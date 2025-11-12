/*-
 * Copyright (C) 2023 Fyra Labs
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

namespace Abacus {
    public class HistoryEntry : Object {
        public string expression { get; set; }
        public string result { get; set; }

        public HistoryEntry (string expr, string res) {
            expression = expr;
            result = res;
        }

        public string to_csv_line () {
            // Escape quotes and newlines for CSV
            var escaped_expr = expression.replace ("\"", "\"\"").replace ("\n", "\\n");
            var escaped_result = result.replace ("\"", "\"\"").replace ("\n", "\\n");
            return @"\"$escaped_expr\",\"$escaped_result\"";
        }

        public static HistoryEntry? from_csv_line (string line) {
            // Simple CSV parser for quoted fields
            if (line.strip () == "") {
                return null;
            }

            var fields = new Gee.ArrayList<string> ();
            var in_quotes = false;
            var current_field = new StringBuilder ();
            var i = 0;

            while (i < line.length) {
                var c = line[i];

                if (c == '"') {
                    if (in_quotes && i + 1 < line.length && line[i + 1] == '"') {
                        // Escaped quote
                        current_field.append_c ('"');
                        i += 2;
                        continue;
                    } else {
                        in_quotes = !in_quotes;
                        i++;
                        continue;
                    }
                } else if (c == ',' && !in_quotes) {
                    fields.add (current_field.str.replace ("\\n", "\n"));
                    current_field = new StringBuilder ();
                    i++;
                    continue;
                }

                current_field.append_c (c);
                i++;
            }

            fields.add (current_field.str.replace ("\\n", "\n"));

            if (fields.size >= 2) {
                return new HistoryEntry (fields[0], fields[1]);
            }

            return null;
        }
    }

    public class History : Object {
        private Gee.ArrayList<HistoryEntry> entries;
        private const int MAX_ENTRIES = 10;
        private string history_file_path;

        public signal void changed ();

        public History () {
            entries = new Gee.ArrayList<HistoryEntry> ();

            // Set up history file path
            var data_dir = Path.build_filename (
                Environment.get_user_data_dir (),
                "com.fyralabs.Abacus"
            );

            // Create directory if it doesn't exist
            var dir = File.new_for_path (data_dir);
            try {
                if (!dir.query_exists ()) {
                    dir.make_directory_with_parents ();
                }
            } catch (Error e) {
                warning ("Failed to create data directory: %s", e.message);
            }

            history_file_path = Path.build_filename (data_dir, "history.csv");

            // Load existing history
            load_from_file ();
        }

        public void add_entry (string expression, string result) {
            // Don't add if expression equals result (no calculation was done)
            if (expression == result) {
                return;
            }

            // Don't add duplicates of the most recent entry
            if (entries.size > 0) {
                var last = entries[entries.size - 1];
                if (last.expression == expression && last.result == result) {
                    return;
                }
            }

            var entry = new HistoryEntry (expression, result);
            entries.add (entry);

            // Keep only the last 10 entries
            if (entries.size > MAX_ENTRIES) {
                entries.remove_at (0);
            }

            save_to_file ();
            changed ();
        }

        public void remove_entry (int index) {
            if (index >= 0 && index < entries.size) {
                entries.remove_at (index);
                save_to_file ();
                changed ();
            }
        }

        public void clear () {
            entries.clear ();
            save_to_file ();
            changed ();
        }

        public Gee.ArrayList<HistoryEntry> get_entries () {
            return entries;
        }

        public int get_count () {
            return entries.size;
        }

        public HistoryEntry? get_entry (int index) {
            if (index >= 0 && index < entries.size) {
                return entries[index];
            }
            return null;
        }

        private void save_to_file () {
            try {
                var file = File.new_for_path (history_file_path);
                var output_stream = file.replace (null, false, FileCreateFlags.NONE);
                var data_stream = new DataOutputStream (output_stream);

                // Write CSV header
                data_stream.put_string ("expression,result\n");

                // Write each entry
                foreach (var entry in entries) {
                    data_stream.put_string (entry.to_csv_line () + "\n");
                }

                data_stream.close ();
            } catch (Error e) {
                warning ("Failed to save history: %s", e.message);
            }
        }

        private void load_from_file () {
            try {
                var file = File.new_for_path (history_file_path);

                if (!file.query_exists ()) {
                    return;
                }

                var input_stream = file.read ();
                var data_stream = new DataInputStream (input_stream);

                string? line = null;
                bool first_line = true;

                while ((line = data_stream.read_line ()) != null) {
                    // Skip header line
                    if (first_line) {
                        first_line = false;
                        continue;
                    }

                    var entry = HistoryEntry.from_csv_line (line);
                    if (entry != null) {
                        entries.add (entry);
                    }
                }

                data_stream.close ();

                // Ensure we don't exceed max entries after loading
                while (entries.size > MAX_ENTRIES) {
                    entries.remove_at (0);
                }
            } catch (Error e) {
                warning ("Failed to load history: %s", e.message);
            }
        }
    }
}
