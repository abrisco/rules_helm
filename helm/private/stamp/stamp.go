package stamp

import (
	"fmt"
	"os"
	"strings"
)

func LoadStamps(stampFiles ...string) (map[string]string, error) {
	stamps := map[string]string{}

	for _, stampFile := range stampFiles {
		// The files may not be defined
		if len(stampFile) == 0 {
			continue
		}

		content, err := os.ReadFile(stampFile)
		if err != nil {
			return nil, fmt.Errorf("Error reading file %s: %w", stampFile, err)
		}

		for _, line := range strings.Split(string(content), "\n") {
			split := strings.SplitN(line, " ", 2)
			if len(split) < 2 {
				continue
			}
			key, val := split[0], split[1]
			stamps[key] = val
		}
	}

	return stamps, nil
}

func ReplaceKeyValues(content string, stamps map[string]string) (string, error) {
	for key, value := range stamps {
		replaceKey := fmt.Sprintf("{%s}", key)
		content = strings.ReplaceAll(content, replaceKey, value)
	}

	return content, nil
}
