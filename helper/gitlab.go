package helper

import (
	"fmt"
	"log"
	"net"
	"sort"
	"strconv"
	"strings"

	gitlab "gitlab.com/gitlab-org/api/client-go"
	"go.uber.org/zap"
)

func GenerateGitlabIssue(zones []SubnetResponse, pat, api, projectID, zone string, logger *zap.Logger, includeEmpty bool, inner *string, project *gitlab.Project, items []*gitlab.Issue, client *gitlab.Client, labelMapping []Label) {

	if inner != nil && *inner != "" {
		innerMask, err := strconv.Atoi(*inner)
		if err != nil {
			log.Fatal(err)
		}
		innerNets, err := Subnets(zone, innerMask)
		if err != nil {
			log.Fatal(err)
		}
		for _, innerNet := range innerNets {
			var innerZones []SubnetResponse
			for _, zone := range zones {
				ip, _, _ := net.ParseCIDR(zone.Net)
				if innerNet.Contains(ip) {
					innerZones = append(innerZones, zone)
				}
			}
			GenerateGitlabIssue(innerZones, pat, api, projectID, innerNet.String(), logger, includeEmpty, nil, project, items, client, labelMapping)
		}
		return
	}

	sort.Sort(ByNet(zones))
	var description string
	var i int
	if len(zones) == 1 {
		description = zones[0].Section
		if len([]byte(description)) > (1024 * 512) {
			logger.Sugar().Fatalf("Issue description will be to large. Consider splitting information into subnets.")
		}
	} else {
		for _, item := range zones {
			if len([]byte(description)) > (1024 * 512) {
				description += "\n\nPlease check comments."
				break
			}
			description += generateDescription(item, includeEmpty)
			i++
		}
	}
	var issues []*gitlab.Issue
	var issue *gitlab.Issue
	var err error
	for _, item := range items {
		if item.Title == "IP usage in "+zone {
			issues = append(issues, item)
			continue
		}
		if item.Title == "Free IPs in "+zone {
			issues = append(issues, item)
			continue
		}
	}
	if len(issues) == 0 {
		if zones[0].Empty && !includeEmpty {
			logger.Sugar().Infof("Zone %s is empty. Skipping", zone)
			return
		}
		logger.Sugar().Infof("Found no existing issue for zone %s. Creating new.", zone)
		var matchingLabels []string
		for _, labelMapping := range labelMapping {
			if labelMapping.Subnet == zone {
				matchingLabels = append(matchingLabels, labelMapping.Label)
				break
			}
			cont, err := contains(zone, labelMapping.Subnet)
			if err != nil {
				panic(err)
			}
			if cont {
				matchingLabels = append(matchingLabels, labelMapping.Label)
			}
		}

		issue, _, err = client.Issues.CreateIssue(project.ID, &gitlab.CreateIssueOptions{
			Title:       gitlab.Ptr("IP usage in " + zone),
			Description: gitlab.Ptr(""),
			Labels:      &gitlab.LabelOptions{strings.Join(matchingLabels, ",")},
		})
		if err != nil {
			panic(err)
		}

	} else {
		if zones[0].Empty && !includeEmpty {
			for _, issue := range issues {
				logger.Sugar().Infof("Zone %s is empty. Deleting existing issue", zone)
				_, err := client.Issues.DeleteIssue(project.ID, issue.IID)
				if err != nil {
					logger.Sugar().Warnf("Deleting issue %s failed.", issue.Title)
					_, _, err := client.Issues.UpdateIssue(project.ID, issue.IID, &gitlab.UpdateIssueOptions{StateEvent: gitlab.Ptr("close")})
					if err != nil {
						logger.Sugar().Errorf("Closing issue %s failed.", issue.Title)
					}
				}
			}
			return
		}
		if len(issues) > 1 {
			failed := false
			for _, issue := range issues[1:] {
				logger.Sugar().Infof("Deleting duplicate issue for %s", zone)
				_, err := client.Issues.DeleteIssue(project.ID, issue.IID)
				if err != nil {
					logger.Sugar().Warnf("Deleting issue %s failed.", issue.Title)
					failed = true
				}
			}
			if failed {
				for i, issue := range issues {
					_, _, err := client.Issues.UpdateIssue(project.ID, issue.IID, &gitlab.UpdateIssueOptions{StateEvent: gitlab.Ptr("close")})
					if err != nil {
						logger.Sugar().Errorf("Closing issue %s failed.", issue.Title)
					}
					issues[i].State = "closed"
				}
			}
		}
		issue = issues[0]
	}

	logger.Sugar().Infof("Updating issue description for zone %s.", zone)
	var matchingLabels []string
	for _, labelMapping := range labelMapping {
		if labelMapping.Subnet == zone {
			matchingLabels = append(matchingLabels, labelMapping.Label)
			break
		}
		cont, err := contains(zone, labelMapping.Subnet)
		if err != nil {
			panic(err)
		}
		if cont {
			matchingLabels = append(matchingLabels, labelMapping.Label)
		}
	}
	update := &gitlab.UpdateIssueOptions{
		Title:       gitlab.Ptr("IP usage in " + zone),
		Description: gitlab.Ptr(description),
		Labels:      &gitlab.LabelOptions{strings.Join(matchingLabels, ",")},
	}
	if issue.State == "closed" {
		logger.Sugar().Warnf("Reopening issue for %s", zone)
		update.StateEvent = gitlab.Ptr("reopen")
	}
	_, _, err = client.Issues.UpdateIssue(project.ID, issue.IID, update)
	if err != nil {
		logger.Sugar().Errorf("Updating issue %s failed.", issue.Title)
	}
	notes, _, err := client.Notes.ListIssueNotes(project.ID, issue.IID, &gitlab.ListIssueNotesOptions{})
	if err != nil {
		panic(err)
	}
	if len(notes) != 0 {
		logger.Sugar().Infof("Purging old comments for zone %s", zone)
	}
	for _, note := range notes {
		if !note.System {
			logger.Sugar().Infof("Deleting comment %s", note.Body)
			_, err = client.Notes.DeleteIssueNote(project.ID, issue.IID, note.ID)
			if err != nil {
				logger.Sugar().Errorf("Deleting comment %s failed. This commonly happens due to missing permissions. Maybe the comment was created by somebody else? (Error: %v)", note.Body, err)
			}
		}
	}
	if len(zones) != 1 && len(zones) != i {
		logger.Sugar().Infof("Description handles %d subnets. %d remaining -> Placing into comments", i, len(zones)-i)
		for {
			description = ""
			inserted := false
			for _, item := range zones[i:] {
				if len([]byte(description)) > (1024 * 512) {
					description += "\n\nPlease check comments"
					_, _, err := client.Notes.CreateIssueNote(project.ID, issue.IID, &gitlab.CreateIssueNoteOptions{Body: gitlab.Ptr(description)})
					if err != nil {
						logger.Sugar().Fatal(zap.Error(err))
					}
					inserted = true
					break
				}
				description += generateDescription(item, includeEmpty)
				i++
			}
			if i == len(zones) {
				if !inserted {
					_, _, err := client.Notes.CreateIssueNote(project.ID, issue.IID, &gitlab.CreateIssueNoteOptions{Body: gitlab.Ptr(description)})
					if err != nil {
						logger.Sugar().Fatal(zap.Error(err))
					}
				}
				break
			}
		}
	}
}

func generateDescription(net SubnetResponse, empty bool) string {
	if !net.Empty {
		return fmt.Sprintf("## %s \n<details><summary>IPs:</summary>\n\n%s\n</details>\n\n", net.Net, net.Section)
	} else if empty {
		return fmt.Sprintf("## %s\n\n%s\n\n\n", net.Net, net.Section)
	}
	return ""
}
