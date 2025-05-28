package cmd

import (
	"log"
	"os"
	"path"
	"regexp"
	"slices"
	"strings"

	"github.com/miekg/dns"
	"github.com/spf13/cobra"
)

// runCmd represents the run command
var duplicateCommand = &cobra.Command{
	Use:   "duplicate",
	Short: "Parse the reverse zones and determine the duplicate records",
	Run: func(cmd *cobra.Command, args []string) {
		dir, _ := cmd.Flags().GetString("dir")
		fileNameFormats, _ := cmd.Flags().GetStringSlice("formats")

		var zp *dns.ZoneParser
		var records []dns.RR
		for _, format := range fileNameFormats {

			// Iterate over all files in the directory and check if the file matches the format
			files, err := os.ReadDir(dir)
			if err != nil {
				log.Fatal(err)
			}
			for _, file := range files {
				if ok, err := regexp.MatchString(format, file.Name()); ok && err == nil && !file.IsDir() {
					fileName := file.Name()
					content, err := os.ReadFile(path.Join(dir, fileName))
					if err != nil {
						log.Printf("Error reading file %s: %v", fileName, err)
						continue
					}
					// Extract the origin from the file name
					pat, err := regexp.Compile(format)
					if err != nil {
						log.Printf("Error compiling regex %s: %v", format, err)
						continue
					}
					matches := pat.FindStringSubmatch(fileName)
					if len(matches) < 2 {
						log.Printf("No match found for file %s with pattern %s", fileName, format)
						continue
					}
					origin := matches[1]
					if origin == "" {
						log.Printf("No origin found in file name %s with pattern %s", fileName, format)
						continue
					}
					zp = dns.NewZoneParser(strings.NewReader(string(content)), origin, fileName)
					for rr, ok := zp.Next(); ok; rr, ok = zp.Next() {
						records = append(records, rr)
					}
				}
			}
		}
		duplicatesFound := false
		duplicates := make(map[string][]string)
		for i := 0; i < len(records); i++ {
			// Check if record is a PTR record
			if records[i].Header().Rrtype != dns.TypePTR {
				continue
			}
			for j := 0; j < len(records); j++ {
				// Check if record is a PTR record
				if records[j].Header().Rrtype != dns.TypePTR {
					continue
				}
				// parse to specific type
				r, ok := records[i].(*dns.PTR)
				if !ok {
					log.Printf("Record %d is not a PTR record: %s", i, records[i].String())
					continue
				}
				s, ok := records[j].(*dns.PTR)
				if !ok {
					log.Printf("Record %d is not a PTR record: %s", j, records[j].String())
					continue
				}
				// Check if the records are duplicates
				if r.Hdr.Name == s.Hdr.Name && r.Ptr != s.Ptr {
					duplicatesFound = true
					// Add the duplicate record to the map if it doesn't already exist
					if _, exists := duplicates[r.Hdr.Name]; !exists {
						duplicates[r.Hdr.Name] = []string{r.Ptr}
					} else {
						// Append the new duplicate record
						if !slices.Contains(duplicates[r.Hdr.Name], r.Ptr) {
							duplicates[r.Hdr.Name] = append(duplicates[r.Hdr.Name], r.Ptr)
						}
					}
				}
			}
		}
		if duplicatesFound {
			log.Println("Duplicate PTR records found:")
			for name, ptrs := range duplicates {
				log.Printf("Name: %s, Duplicates: %s", name, strings.Join(ptrs, ", "))
			}
			os.Exit(1)
		} else {
			log.Println("No duplicate PTR records found.")
		}
	},
}

func init() {
	rootCmd.AddCommand(duplicateCommand)

	duplicateCommand.Flags().StringP("dir", "d", "zones", "the location of reverse zones")
	duplicateCommand.Flags().StringSliceP("formats", "f", []string{`zone\.(.*)`, `(.*)\.zone`, `(.*)\.db`, `db\.(.*)`}, "the filename patterns to search the reverse zone")

	duplicateCommand.MarkFlagRequired("zone")

}
