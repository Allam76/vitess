/*
Copyright 2019 The Vitess Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package sysloglogger

import (
	"errors"
	"fmt"
	"log/syslog"
	"strconv"
	"strings"
	"testing"
	"time"

	"golang.org/x/net/context"

	"github.com/liquidata-inc/vitess/go/streamlog"
	"github.com/liquidata-inc/vitess/go/vt/vttablet/tabletserver/tabletenv"
)

// fakeWriter is a mock of the real syslog writer, to enable capturing and playing back of log messages in unit testing.
type fakeWriter struct {
	messages map[string]bool
}

func newFakeWriter() *fakeWriter {
	return &fakeWriter{
		messages: make(map[string]bool),
	}
}
func (fw *fakeWriter) write(pri syslog.Priority, msg string) error {
	fw.messages[strings.TrimSpace(msg)] = true
	return nil
}
func (fw *fakeWriter) Info(msg string) error { return fw.write(syslog.LOG_INFO, msg) }
func (fw *fakeWriter) Close() error          { return nil }

// mockLogStats generates a dummy tabletserver.LogStats message for testing.
func mockLogStats(originalSQL string) *tabletenv.LogStats {
	logstats := tabletenv.NewLogStats(context.Background(), "Execute")
	logstats.StartTime = time.Time{}
	logstats.PlanType = "PASS_SELECT"
	logstats.OriginalSQL = originalSQL
	logstats.AddRewrittenSQL(originalSQL, time.Now())
	logstats.MysqlResponseTime = 0
	return logstats
}

// failingFakeWriter is a mock syslog writer that deliberately simulates an intermittent syslog outage, which causes
// every 4th message log message to be dropped.
type failingFakeWriter struct {
	messages        map[string]bool
	numberProcessed int
}

func newFailingFakeWriter() *failingFakeWriter {
	return &failingFakeWriter{
		messages:        make(map[string]bool),
		numberProcessed: 0,
	}
}
func (fw *failingFakeWriter) write(pri syslog.Priority, msg string) error {
	fw.numberProcessed++
	if fw.numberProcessed%4 == 0 {
		return errors.New("Cannot connect to syslog")
	}
	fw.messages[strings.TrimSpace(msg)] = true
	return nil
}
func (fw *failingFakeWriter) Info(msg string) error { return fw.write(syslog.LOG_INFO, msg) }
func (fw *failingFakeWriter) Close() error          { return nil }

// expectedLogStatsText returns the results expected from the plugin processing a dummy message generated by mockLogStats(...).
func expectedLogStatsText(originalSQL string) string {
	return fmt.Sprintf("Execute\t\t\t''\t''\t0001-01-01 00:00:00.000000\t0001-01-01 00:00:00.000000\t0.000000\tPASS_SELECT\t"+
		"\"%s\"\t%s\t1\t\"%s\"\tmysql\t0.000000\t0.000000\t0\t0\t\"\"", originalSQL, "map[]", originalSQL)
}

// expectedRedactedLogStatsText returns the results expected from the plugin processing a dummy message generated by mockLogStats(...)
// when redaction is enabled.
func expectedRedactedLogStatsText(originalSQL string) string {
	return fmt.Sprintf("Execute\t\t\t''\t''\t0001-01-01 00:00:00.000000\t0001-01-01 00:00:00.000000\t0.000000\tPASS_SELECT\t"+
		"\"%s\"\t%q\t1\t\"%s\"\tmysql\t0.000000\t0.000000\t0\t0\t\"\"", originalSQL, "[REDACTED]", "[REDACTED]")
}

// TestSyslog sends a stream of five query records to the plugin, and verifies that they are logged.
func TestSyslog(t *testing.T) {
	// Overwrite the usual syslog writer and StatsLogger subscription channel with mocks
	mock := newFakeWriter()
	writer = mock
	ch = make(chan interface{}, 10)

	// Start running the plugin loop
	syncChannel := make(chan bool)
	go func() {
		run()
		close(syncChannel)
	}()

	// Send fake messages to the mock channel, and then close the channel to end the plugin loop
	ch <- mockLogStats("select 1")
	ch <- mockLogStats("select 2")
	ch <- mockLogStats("select 3")
	ch <- mockLogStats("select 4")
	ch <- mockLogStats("select 5")
	close(ch)
	<-syncChannel

	// Collect everything that the plugin logged
	queriesLogged := make(map[string]bool)
	for received := range mock.messages {
		t.Logf("Logged query \"%s\"", received)
		queriesLogged[received] = true
	}

	// Verify the count and contents
	if len(queriesLogged) != 5 {
		t.Fatalf("Expected 5 queries to be logged, but found %d", len(queriesLogged))
	}
	for i := 1; i <= 5; i++ {
		if _, ok := queriesLogged[expectedLogStatsText("select "+strconv.Itoa(i))]; !ok {
			t.Fatalf("Expected query \"%s\" was not logged", expectedLogStatsText("select "+strconv.Itoa(i)))
		}
	}
}

// TestSyslogRedacted sends a stream of five query records to the plugin, and verifies that they are logged
// when redaction is enabled.
func TestSyslogRedacted(t *testing.T) {
	// Overwrite the usual syslog writer and StatsLogger subscription channel with mocks
	*streamlog.RedactDebugUIQueries = true
	defer func() {
		*streamlog.RedactDebugUIQueries = false
	}()
	mock := newFakeWriter()
	writer = mock
	ch = make(chan interface{}, 10)

	// Start running the plugin loop
	syncChannel := make(chan bool)
	go func() {
		run()
		close(syncChannel)
	}()

	// Send fake messages to the mock channel, and then close the channel to end the plugin loop
	ch <- mockLogStats("select 1")
	ch <- mockLogStats("select 2")
	ch <- mockLogStats("select 3")
	ch <- mockLogStats("select 4")
	ch <- mockLogStats("select 5")
	close(ch)
	<-syncChannel

	// Collect everything that the plugin logged
	queriesLogged := make(map[string]bool)
	for received := range mock.messages {
		t.Logf("Logged query \"%s\"", received)
		queriesLogged[received] = true
	}

	// Verify the count and contents
	if len(queriesLogged) != 5 {
		t.Fatalf("Expected 5 queries to be logged, but found %d", len(queriesLogged))
	}
	for i := 1; i <= 5; i++ {
		if _, ok := queriesLogged[expectedRedactedLogStatsText("select "+strconv.Itoa(i))]; !ok {
			t.Fatalf("Expected query \"%s\" was not logged", expectedRedactedLogStatsText("select "+strconv.Itoa(i)))
		}
	}
}

// TestSyslogWithBadData sends a stream of query records, including one that doesn't fit the type specification...
// verifying that the bad record is gracefully skipped and the others are still logged successfully.
func TestSyslogWithBadData(t *testing.T) {
	mock := newFakeWriter()
	writer = mock
	ch = make(chan interface{}, 10)

	syncChannel := make(chan bool)
	go func() {
		run()
		close(syncChannel)
	}()

	// Send 5 records for logging, one of which is bad
	ch <- mockLogStats("select 1")
	ch <- mockLogStats("select 2")
	ch <- mockLogStats("select 3")
	ch <- "Wait... this is just a garbage 'string', not of type '*tabletserver.LogStats'!"
	ch <- mockLogStats("select 5")
	close(ch)
	<-syncChannel

	// Collect everything that the plugin logged
	queriesLogged := make(map[string]bool)
	for received := range mock.messages {
		queriesLogged[received] = true
	}

	// Verify the count and contents
	if len(queriesLogged) != 4 {
		t.Fatalf("Expected 4 queries to be logged, but found %d", len(queriesLogged))
	}
	validNums := []int{1, 2, 3, 5}
	for _, num := range validNums {
		if _, ok := queriesLogged[expectedLogStatsText("select "+strconv.Itoa(num))]; !ok {
			t.Fatalf("Expected query \"%s\" was not logged", expectedLogStatsText("select "+strconv.Itoa(num)))
		}
	}
}

// TestSyslogWithInterruptedConnection sends a stream of query records, simulating temporary syslog outage
// while they're processing.  Verifies that the plugin gracefully handles and recovers from the broken connectivity,
// and that all messages received while the connection is alive are logged successfully.
func TestSyslogWithInterruptedConnection(t *testing.T) {

	// This mock will simulate a broken syslog connection when processing every 4th record
	mock := newFailingFakeWriter()
	writer = mock
	ch = make(chan interface{}, 10)

	syncChannel := make(chan bool)
	go func() {
		run()
		close(syncChannel)
	}()

	ch <- mockLogStats("select 1")
	ch <- mockLogStats("select 2")
	ch <- mockLogStats("select 3")
	ch <- mockLogStats("select 4") // This record will get dropped due to a syslog outage
	ch <- mockLogStats("select 5")
	close(ch)
	<-syncChannel

	queriesLogged := make(map[string]bool)
	for received := range mock.messages {
		queriesLogged[received] = true
	}
	if len(queriesLogged) != 4 {
		t.Fatalf("Expected 4 queries to be logged, but found %d", len(queriesLogged))
	}
	expectedLogs := []int{1, 2, 3, 5}
	for _, num := range expectedLogs {
		if _, ok := queriesLogged[expectedLogStatsText("select "+strconv.Itoa(num))]; !ok {
			t.Fatalf("Expected query \"%s\" was not logged", expectedLogStatsText("select "+strconv.Itoa(num)))
		}
	}
}
