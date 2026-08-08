package helm_utils

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/bazelbuild/rules_go/go/runfiles"
)

// clearImagePushConcurrency removes the override for the duration of the test,
// so a value the developer has exported cannot decide the outcome. `t.Setenv`
// has no unset form, but calling it registers the cleanup that puts their value
// back.
func clearImagePushConcurrency(t *testing.T) {
	t.Helper()

	t.Setenv(ImagePushConcurrencyEnvVar, "")
	if err := os.Unsetenv(ImagePushConcurrencyEnvVar); err != nil {
		t.Fatalf("Failed to unset %s: %v", ImagePushConcurrencyEnvVar, err)
	}
}

// requireImagePushers skips a test that cannot run outside Bazel.
// RunImagePushers resolves the runfiles environment it hands to each pusher, and
// the pusher stand-ins are shell scripts.
func requireImagePushers(t *testing.T) {
	t.Helper()

	if runtime.GOOS == "windows" {
		t.Skip("pusher stand-ins are shell scripts")
	}
	if _, err := runfiles.New(); err != nil {
		t.Skipf("no runfiles, so image pushers cannot be run: %v", err)
	}
}

func TestImagePushConcurrencyDefault(t *testing.T) {
	clearImagePushConcurrency(t)

	if got := imagePushConcurrency(100); got != defaultImagePushConcurrency {
		t.Errorf("imagePushConcurrency(100) = %d, want %d", got, defaultImagePushConcurrency)
	}
}

func TestImagePushConcurrencyClampsToPusherCount(t *testing.T) {
	clearImagePushConcurrency(t)

	if got := imagePushConcurrency(3); got != 3 {
		t.Errorf("imagePushConcurrency(3) = %d, want 3", got)
	}
}

func TestImagePushConcurrencyEnvOverride(t *testing.T) {
	t.Setenv(ImagePushConcurrencyEnvVar, "2")

	if got := imagePushConcurrency(100); got != 2 {
		t.Errorf("imagePushConcurrency(100) = %d, want 2", got)
	}
}

func TestImagePushConcurrencyInvalidEnvOverride(t *testing.T) {
	for _, raw := range []string{"0", "-1", "many", ""} {
		t.Run(fmt.Sprintf("value=%q", raw), func(t *testing.T) {
			t.Setenv(ImagePushConcurrencyEnvVar, raw)

			if got := imagePushConcurrency(100); got != defaultImagePushConcurrency {
				t.Errorf("imagePushConcurrency(100) = %d, want %d", got, defaultImagePushConcurrency)
			}
		})
	}
}

// writePusher creates an executable stand-in for an image pusher.
func writePusher(t *testing.T, dir string, name string, body string) string {
	t.Helper()

	path := filepath.Join(dir, name)
	script := "#!/usr/bin/env bash\nset -euo pipefail\n" + body
	if err := os.WriteFile(path, []byte(script), 0o755); err != nil {
		t.Fatalf("Failed to write pusher %s: %v", path, err)
	}

	return path
}

// captureStdout redirects os.Stdout for the duration of fn and returns what was
// written to it.
func captureStdout(t *testing.T, fn func()) string {
	t.Helper()

	path := filepath.Join(t.TempDir(), "stdout")
	file, err := os.Create(path)
	if err != nil {
		t.Fatalf("Failed to create capture file: %v", err)
	}

	original := os.Stdout
	os.Stdout = file
	defer func() {
		os.Stdout = original
		file.Close()
	}()

	fn()

	if err := file.Sync(); err != nil {
		t.Fatalf("Failed to sync capture file: %v", err)
	}

	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("Failed to read capture file: %v", err)
	}

	return string(content)
}

func TestRunImagePushersNoPushers(t *testing.T) {
	if err := RunImagePushers(nil); err != nil {
		t.Errorf("RunImagePushers(nil) = %v, want nil", err)
	}
}

func TestRunImagePushersRunsEveryPusher(t *testing.T) {
	requireImagePushers(t)

	dir := t.TempDir()
	outputs := filepath.Join(dir, "outputs")
	if err := os.Mkdir(outputs, 0o755); err != nil {
		t.Fatalf("Failed to create outputs dir: %v", err)
	}

	var pushers []string
	for i := 0; i < 5; i++ {
		pushers = append(pushers, writePusher(t, dir, fmt.Sprintf("pusher%d", i),
			fmt.Sprintf("touch %q\n", filepath.Join(outputs, fmt.Sprintf("ran%d", i)))))
	}

	captureStdout(t, func() {
		if err := RunImagePushers(pushers); err != nil {
			t.Errorf("RunImagePushers() = %v, want nil", err)
		}
	})

	entries, err := os.ReadDir(outputs)
	if err != nil {
		t.Fatalf("Failed to read outputs dir: %v", err)
	}
	if len(entries) != len(pushers) {
		t.Errorf("%d pushers ran, want %d", len(entries), len(pushers))
	}
}

// Pushers must actually overlap in time, and each one's output must still land
// as a single contiguous block.
//
// The barrier is driven by the test, not by the pushers watching each other:
// every pusher reports that it started and then blocks until the test releases
// it. That keeps the check off the wall clock. A machine too loaded to start all
// the pushers promptly reports how many did start, rather than failing as though
// the production code had stopped running them concurrently. Once released they
// all write at once, which a naive implementation streaming straight to stdout
// cannot keep contiguous.
func TestRunImagePushersIsConcurrentWithoutInterleavingOutput(t *testing.T) {
	requireImagePushers(t)

	const (
		pusherCount  = 4
		linesPerPush = 200
		marker       = "line"
		barrierWait  = 30 * time.Second
	)

	dir := t.TempDir()
	rendezvous := filepath.Join(dir, "rendezvous")
	if err := os.Mkdir(rendezvous, 0o755); err != nil {
		t.Fatalf("Failed to create rendezvous dir: %v", err)
	}
	release := filepath.Join(rendezvous, "release")

	t.Setenv(ImagePushConcurrencyEnvVar, strconv.Itoa(pusherCount))

	// Waiting on the release file uses a shell builtin, so a blocked pusher
	// costs one `sleep` per poll rather than a pipeline of subprocesses.
	var pushers []string
	for i := 0; i < pusherCount; i++ {
		pushers = append(pushers, writePusher(t, dir, fmt.Sprintf("pusher%d", i), fmt.Sprintf(`
touch %[1]q/started%[2]d
for _ in $(seq 1 6000); do
  if [ -f %[3]q ]; then
    for j in $(seq 1 %[4]d); do echo "p%[2]d %[5]s $j"; done
    exit 0
  fi
  sleep 0.01
done
echo "timed out waiting for the test to release this pusher" >&2
exit 1
`, rendezvous, i, release, linesPerPush, marker)))
	}

	// Reported over a channel rather than through `t`: this goroutine can outlive
	// a failed assertion, and logging from it after the test has finished panics.
	type barrier struct {
		started int
		err     error
	}
	barrierDone := make(chan barrier, 1)
	abandon := make(chan struct{})
	defer close(abandon)

	go func() {
		deadline := time.Now().Add(barrierWait)
		for {
			count := 0
			if entries, err := os.ReadDir(rendezvous); err == nil {
				for _, entry := range entries {
					if strings.HasPrefix(entry.Name(), "started") {
						count++
					}
				}
			}

			if count >= pusherCount || time.Now().After(deadline) {
				// Released even on timeout, so no pusher is left blocking on a
				// barrier the test has already given up on.
				barrierDone <- barrier{started: count, err: os.WriteFile(release, nil, 0o644)}
				return
			}

			select {
			case <-abandon:
				// The pushers failed before reaching the barrier, so there is
				// nothing left to release and no reason to wait out the deadline.
				return
			case <-time.After(5 * time.Millisecond):
			}
		}
	}()

	var runErr error
	stdout := captureStdout(t, func() {
		runErr = RunImagePushers(pushers)
	})

	// Checked before the barrier: a failure to run the pushers at all is the
	// cause, and reporting "they did not run concurrently" on top of it would
	// point at the wrong thing.
	if runErr != nil {
		t.Fatalf("RunImagePushers() = %v, want nil", runErr)
	}

	result := <-barrierDone
	if result.err != nil {
		t.Fatalf("Failed to write release file: %v", result.err)
	}
	if result.started < pusherCount {
		t.Fatalf("only %d of %d pushers started within %s, so they did not run concurrently", result.started, pusherCount, barrierWait)
	}

	// Collapse the output to the pusher responsible for each body line.
	var sequence []string
	for _, line := range strings.Split(stdout, "\n") {
		if !strings.Contains(line, marker) {
			continue
		}
		sequence = append(sequence, strings.Fields(line)[0])
	}

	if len(sequence) != pusherCount*linesPerPush {
		t.Fatalf("captured %d body lines, want %d", len(sequence), pusherCount*linesPerPush)
	}

	// One contiguous block per pusher means the owner changes exactly
	// pusherCount-1 times.
	transitions := 0
	for i := 1; i < len(sequence); i++ {
		if sequence[i] != sequence[i-1] {
			transitions++
		}
	}
	if transitions != pusherCount-1 {
		t.Errorf("output interleaved: %d owner transitions, want %d", transitions, pusherCount-1)
	}
}

func TestRunImagePushersJoinsAllFailures(t *testing.T) {
	requireImagePushers(t)

	// Pinned above 1: the assertions below read the buffered blocks, which a
	// serial run does not produce.
	t.Setenv(ImagePushConcurrencyEnvVar, "4")

	dir := t.TempDir()
	pushers := []string{
		writePusher(t, dir, "ok0", "echo fine\n"),
		writePusher(t, dir, "bad1", "echo boom >&2\nexit 3\n"),
		writePusher(t, dir, "ok2", "echo fine\n"),
		writePusher(t, dir, "bad3", "exit 4\n"),
	}

	var err error
	stdout := captureStdout(t, func() {
		err = RunImagePushers(pushers)
	})

	if err == nil {
		t.Fatal("RunImagePushers() = nil, want an error")
	}

	// A failing pusher must not stop the others, and every failure must be
	// reported rather than only the first.
	for _, want := range []string{"bad1", "bad3"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error does not mention %s: %v", want, err)
		}
	}
	if strings.Count(stdout, "Output from image pusher") != len(pushers) {
		t.Errorf("not every pusher ran. Output:\n%s", stdout)
	}

	// A failing pusher's diagnostics have to survive the buffering.
	if !strings.Contains(stdout, "boom") {
		t.Errorf("failing pusher's stderr was dropped. Output:\n%s", stdout)
	}
}

// At a concurrency of 1 there is nothing to protect the output from, so pushers
// must write through live on their own streams instead of being captured and
// replayed. This is what makes RULES_HELM_IMAGE_PUSH_CONCURRENCY=1 a true
// fallback to the original serial behaviour.
func TestRunImagePushersStreamsLiveWhenSerial(t *testing.T) {
	requireImagePushers(t)

	t.Setenv(ImagePushConcurrencyEnvVar, "1")

	dir := t.TempDir()
	pushers := []string{
		writePusher(t, dir, "pusher0", "echo 'existing manifest: sha256:abc'\n"),
		writePusher(t, dir, "pusher1", "echo 'existing manifest: sha256:def'\n"),
	}

	stdout := captureStdout(t, func() {
		if err := RunImagePushers(pushers); err != nil {
			t.Errorf("RunImagePushers() = %v, want nil", err)
		}
	})

	for _, want := range []string{"sha256:abc", "sha256:def"} {
		if !strings.Contains(stdout, want) {
			t.Errorf("stdout is missing %s. Output:\n%s", want, stdout)
		}
	}

	if strings.Contains(stdout, "Output from image pusher") {
		t.Errorf("output was captured and replayed rather than streamed live. Output:\n%s", stdout)
	}
}
