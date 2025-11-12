/*-
 * Copyright (C) 2023 Fyra Labs
 *
 * The following code uses parts of the original work,
 * while keeping the original attribution.
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

[GtkTemplate (ui = "/com/fyralabs/Abacus/window.ui")]
public class Abacus.MainWindow : He.ApplicationWindow {
    [GtkChild]
    private unowned He.Button eq;
    [GtkChild]
    private unowned He.Button eq2;
    [GtkChild]
    private unowned He.TextField entry;
    [GtkChild]
    private unowned He.TextField from_entry;
    [GtkChild]
    private unowned He.TextField to_entry;
    [GtkChild]
    private unowned Gtk.Label result;
    [GtkChild]
    private unowned Gtk.Stack stack;
    [GtkChild]
    private unowned Gtk.Stack titlebar_stack;
    [GtkChild]
    private unowned Gtk.ToggleButton converter;
    [GtkChild]
    private unowned Gtk.ToggleButton history;
    [GtkChild]
    private unowned Gtk.MenuButton menu;
    [GtkChild]
    private unowned Gtk.Overlay about_overlay;
    [GtkChild]
    private unowned Gtk.ListBox history_list;

    [GtkChild]
    private unowned He.Button swap_button;
    [GtkChild]
    private unowned Gtk.DropDown units_dropdown;
    [GtkChild]
    private unowned Gtk.DropDown temp_dropdown_from;
    [GtkChild]
    private unowned Gtk.DropDown temp_dropdown_to;
    [GtkChild]
    private unowned Gtk.DropDown mass_dropdown_from;
    [GtkChild]
    private unowned Gtk.DropDown mass_dropdown_to;
    [GtkChild]
    private unowned Gtk.DropDown len_dropdown_from;
    [GtkChild]
    private unowned Gtk.DropDown len_dropdown_to;
    [GtkChild]
    private unowned Gtk.DropDown vol_dropdown_from;
    [GtkChild]
    private unowned Gtk.DropDown vol_dropdown_to;
    [GtkChild]
    private unowned Gtk.DropDown time_dropdown_from;
    [GtkChild]
    private unowned Gtk.DropDown time_dropdown_to;

    private Core.Evaluation eval;
    private int position;
    private int converter_position;
    private int decimal_places;

    private Convertor[] convertors;
    private uint convertor_index;

    private History calc_history;

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_CLEAR = "action-clear";
    public const string ACTION_CLEAR_CONVERTER = "action-clear-converter";
    public const string ACTION_DELETE = "action-delete";
    public const string ACTION_DELETE_CONVERTER = "action-delete-converter";
    public const string ACTION_INSERT = "action-insert";
    public const string ACTION_INSERT_CONVERTER = "action-insert-converter";
    public const string ACTION_ABOUT = "action-about";
    public const string ACTION_PREFS = "action-prefs";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_INSERT, action_insert, "s" },
        { ACTION_INSERT_CONVERTER, action_insert_converter, "s" },
        { ACTION_CLEAR, action_clear },
        { ACTION_CLEAR_CONVERTER, action_clear_converter },
        { ACTION_DELETE, action_delete },
        { ACTION_DELETE_CONVERTER, action_delete_converter },
        { ACTION_ABOUT, action_about },
        { ACTION_PREFS, action_prefs }
    };

    public class MainWindow (He.Application app) {
        Object (
                application: app,
                title: "Abacus"
        );
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);
        eval = new Core.Evaluation ();
        calc_history = new History ();
        decimal_places = 2;

        var application_instance = (Gtk.Application) GLib.Application.get_default ();
        application_instance.set_accels_for_action (ACTION_PREFIX + ACTION_CLEAR, { "Escape" });

        entry.grab_focus ();
        entry.get_internal_entry ().activate.connect (eq_clicked);
        entry.get_internal_entry ().get_delegate ().insert_text.connect (replace_text);

        from_entry.get_internal_entry ().activate.connect (converter_eq_clicked);
        from_entry.get_internal_entry ().get_delegate ().insert_text.connect (converter_replace_text);

        eq.clicked.connect (() => { eq_clicked (); });
        eq2.clicked.connect (() => { converter_eq_clicked (); });

        unichar[] allowed_characters_arr = { '0',
                                             '1',
                                             '2',
                                             '3',
                                             '4',
                                             '5',
                                             '6',
                                             '7',
                                             '8',
                                             '9',
                                             '+',
                                             '-',
                                             '/',
                                             '*',
                                             ',',
                                             '÷',
                                             '×',
                                             '.',
                                             '%' };

        foreach (var chr in allowed_characters_arr) {
            this.allowed_characters.add (chr);
        }

        converter.toggled.connect (() => {
            if (converter.active) {
                history.active = false;
                stack.set_visible_child_name ("converter");
                titlebar_stack.set_visible_child_name ("converter");
            } else if (!history.active) {
                stack.set_visible_child_name ("calculator");
                titlebar_stack.set_visible_child_name ("default");
            }
        });

        history.toggled.connect (() => {
            if (history.active) {
                converter.active = false;
                stack.set_visible_child_name ("history");
                titlebar_stack.set_visible_child_name ("history");
            } else if (!converter.active) {
                stack.set_visible_child_name ("calculator");
                titlebar_stack.set_visible_child_name ("default");
            }
        });

        calc_history.changed.connect (update_history_list);

        swap_button.clicked.connect (swap);
        units_dropdown.notify["selected"].connect (change_units);

        SimpleAction swap_action = new SimpleAction ("swap", null);
        swap_action.activate.connect (swap);
        add_action (swap_action);
        this.get_application ().set_accels_for_action ("win.swap", { "<primary>w" });

        convertors = {
            new TempConvertor ().init (temp_dropdown_from, temp_dropdown_to),
            new MassConvertor ().init (mass_dropdown_from, mass_dropdown_to),
            new LengthConvertor ().init (len_dropdown_from, len_dropdown_to),
            new VolumeConvertor ().init (vol_dropdown_from, vol_dropdown_to),
            new TimeConvertor ().init (time_dropdown_from, time_dropdown_to)
        };
        convertor_index = 0;

        menu.get_popover ().has_arrow = false;

        this.show ();
    }

    public void swap () {
        convertors[convertor_index].swap ();
    }

    public void change_units () {
        /*
         * 0 = Temperature
         * 1 = Mass
         * 2 = Length
         * 3 = Volume
         * 4 = Time
         */

        convertor_index = units_dropdown.get_selected ();
        for (int i = 0; i < convertors.length; i++) {
            convertors[i].hide ();
        }
        convertors[convertor_index].show ();

        from_entry.get_internal_entry ().set_text ("");
        to_entry.get_internal_entry ().set_text ("");

        from_entry.get_internal_entry ().grab_focus ();
    }

    private void action_insert (SimpleAction action, Variant? variant) {
        var token = variant.get_string ();

        // Convert operators to their display symbols
        var display_token = token;
        switch (token) {
        case "/":
            display_token = "÷";
            break;
        case "*":
            display_token = "×";
            break;
        }

        int new_position = entry.get_internal_entry ().get_position ();
        int selection_start, selection_end, selection_length;
        bool is_text_selected = entry.get_internal_entry ().get_selection_bounds (out selection_start, out selection_end);
        if (is_text_selected) {
            new_position = selection_end;
            entry.get_internal_entry ().delete_selection ();
            selection_length = selection_end - selection_start;
            new_position -= selection_length;
        }

        var cursor_position = entry.get_internal_entry ().cursor_position;
        entry.get_internal_entry ().do_insert_text (display_token, -1, ref cursor_position);

        new_position += display_token.char_count ();
        entry.get_internal_entry ().set_position (new_position);
    }

    private void action_insert_converter (SimpleAction action, Variant? variant) {
        var token = variant.get_string ();
        int new_position = from_entry.get_internal_entry ().get_position ();
        int selection_start, selection_end, selection_length;
        bool is_text_selected = from_entry.get_internal_entry ().get_selection_bounds (out selection_start, out selection_end);
        if (is_text_selected) {
            new_position = selection_end;
            from_entry.get_internal_entry ().delete_selection ();
            selection_length = selection_end - selection_start;
            new_position -= selection_length;
        }

        var cursor_position = from_entry.get_internal_entry ().cursor_position;
        from_entry.get_internal_entry ().do_insert_text (token, -1, ref cursor_position);

        new_position += token.char_count ();
        from_entry.get_internal_entry ().set_position (new_position);
    }

    private void eq_clicked () {
        position = entry.get_internal_entry ().get_position ();
        if (entry.get_internal_entry ().get_text () != "") {
            try {
                var input = entry.get_internal_entry ().get_text ();
                var output = eval.evaluate (input, decimal_places);
                result.label = input;
                if (input != output) {
                    calc_history.add_entry (input, output);
                    entry.get_internal_entry ().set_text (output);
                    position = output.length;
                    remove_error ();
                }
            } catch (Core.OUT_ERROR e) {
                result.add_css_class ("error-label");
                result.label = e.message;
            }
        } else {
            remove_error ();
        }

        entry.get_internal_entry ().set_position (position);
    }

    private void remove_error () {
        result.remove_css_class ("error-label");
    }

    private void converter_eq_clicked () {
        converter_position = from_entry.get_internal_entry ().get_position ();
        if (from_entry.get_internal_entry ().get_text () != "") {
            float convert_value = float.parse (from_entry.get_internal_entry ().get_text ());
            string output = convertors[convertor_index].convert (convert_value);
            if (to_entry.get_internal_entry ().get_text () != output) {
                to_entry.get_internal_entry ().set_text (output);
                position = output.length;
            }
        } else {
        }

        to_entry.get_internal_entry ().set_position (position);
    }

    private void action_delete () {
        position = entry.get_internal_entry ().get_position ();
        if (entry.get_internal_entry ().get_text ().length > 0) {
            string new_text = "";
            int index = 0;
            unowned unichar c;
            List<unichar> news = new List<unichar> ();

            for (int i = 0; entry.get_internal_entry ().get_text ().get_next_char (ref index, out c); i++) {
                if (i + 1 != position) {
                    news.append (c);
                }
            }

            foreach (unichar u in news) {
                new_text += u.to_string ();
            }

            entry.get_internal_entry ().set_text (new_text);
        }

        entry.get_internal_entry ().set_position (position - 1);
        result.label = "";
    }

    private void action_delete_converter () {
        converter_position = from_entry.get_internal_entry ().get_position ();
        if (from_entry.get_internal_entry ().get_text ().length > 0) {
            string new_text = "";
            int index = 0;
            unowned unichar c;
            List<unichar> news = new List<unichar> ();

            for (int i = 0; from_entry.get_internal_entry ().get_text ().get_next_char (ref index, out c); i++) {
                if (i + 1 != converter_position) {
                    news.append (c);
                }
            }

            foreach (unichar u in news) {
                new_text += u.to_string ();
            }

            from_entry.get_internal_entry ().set_text (new_text);
        }

        from_entry.get_internal_entry ().set_position (converter_position - 1);
    }

    private void action_clear () {
        position = 0;
        entry.get_internal_entry ().set_text ("");
        result.label = "";
        set_focus (entry);

        entry.get_internal_entry ().set_position (position);
    }

    private void action_clear_converter () {
        converter_position = 0;
        from_entry.get_internal_entry ().set_text ("");
        to_entry.get_internal_entry ().set_text ("");
        set_focus (from_entry.get_internal_entry ());

        from_entry.get_internal_entry ().set_position (converter_position);
    }

    private void action_about () {
        var about = new He.AboutWindow (
                                        this,
                                        "Abacus" + Config.NAME_SUFFIX,
                                        "com.fyralabs.Abacus",
                                        Config.VERSION,
                                        Config.APP_ID,
                                        "https:/fyralabs.com",
                                        "https:/fyralabs.com",
                                        "https:/fyralabs.com",
                                        {},
                                        { "Fyra Labs" },
                                        2022,
                                        He.AboutWindow.Licenses.GPLV3,
                                        He.Colors.PURPLE
        );
        about_overlay.add_overlay (about);
        about.present ();
    }

    private void action_prefs () {
        // TODO: Preferences window
    }

    private Gee.TreeSet<unichar> allowed_characters = new Gee.TreeSet<unichar> ();

    private void replace_text (string new_text, int new_text_length, ref int position) {
        if (new_text == "=") {
            Signal.stop_emission_by_name ((void*) entry.get_internal_entry ().get_delegate (), "insert-text");
            eq_clicked ();
            return;
        }

        for (int i = 0; i < new_text.char_count (); i++) {
            var chr = new_text.get_char (i);
            if (!this.allowed_characters.contains (chr)) {
                Signal.stop_emission_by_name ((void*) entry.get_internal_entry ().get_delegate (), "insert-text");
                return;
            }
        }

        var replacement_text = "";

        switch (new_text) {
        case "." :
        case "," :
            replacement_text = Posix.nl_langinfo (Posix.NLItem.RADIXCHAR);
            break;
        case "/":
            replacement_text = "÷";
            break;
        case "*":
            replacement_text = "×";
            break;
        }

        if (replacement_text != "" && replacement_text != new_text) {
            var cursor_position = entry.get_internal_entry ().cursor_position;
            entry.get_internal_entry ().do_insert_text (replacement_text, -1, ref cursor_position);
            position = cursor_position;
            Signal.stop_emission_by_name ((void*) entry.get_internal_entry ().get_delegate (), "insert-text");
        }
    }

    private void converter_replace_text (string new_text, int new_text_length, ref int position) {
        if (new_text == "=") {
            Signal.stop_emission_by_name ((void*) from_entry.get_internal_entry ().get_delegate (), "insert-text");
            Signal.stop_emission_by_name ((void*) to_entry.get_internal_entry ().get_delegate (), "insert-text");
            converter_eq_clicked ();
            return;
        }

        for (int i = 0; i < new_text.char_count (); i++) {
            var chr = new_text.get_char (i);
            if (!this.allowed_characters.contains (chr)) {
                Signal.stop_emission_by_name ((void*) from_entry.get_internal_entry ().get_delegate (), "insert-text");
                Signal.stop_emission_by_name ((void*) to_entry.get_internal_entry ().get_delegate (), "insert-text");
                return;
            }
        }

        var replacement_text = "";

        if (replacement_text != "" && replacement_text != new_text) {
            from_entry.get_internal_entry ().do_insert_text (replacement_text, from_entry.get_internal_entry ().cursor_position + replacement_text.char_count (), ref position);
            to_entry.get_internal_entry ().do_insert_text (replacement_text, to_entry.get_internal_entry ().cursor_position + replacement_text.char_count (), ref position);
            Signal.stop_emission_by_name ((void*) to_entry.get_internal_entry ().get_delegate (), "insert-text");
            Signal.stop_emission_by_name ((void*) from_entry.get_internal_entry ().get_delegate (), "insert-text");
        }
    }

    private void update_history_list () {
        // Clear existing items
        while (history_list.get_first_child () != null) {
            history_list.remove (history_list.get_first_child ());
        }

        var entries = calc_history.get_entries ();
        // Display in reverse order (newest first)
        for (int i = entries.size - 1; i >= 0; i--) {
            var entry_item = entries[i];
            var row = create_history_row (entry_item, i);
            history_list.append (row);
        }
    }

    private Gtk.Box create_history_row (HistoryEntry entry_item, int index) {
        var row_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

        // Expression and result labels
        var expr_label = new Gtk.Label (entry_item.expression);
        expr_label.xalign = 0;
        expr_label.add_css_class ("cb-title");
        expr_label.add_css_class ("numeric");

        var result_label = new Gtk.Label ("= " + entry_item.result);
        result_label.xalign = 0;
        result_label.add_css_class ("view-subtitle");
        result_label.add_css_class ("numeric");

        // Button box
        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        button_box.halign = Gtk.Align.END;

        var use_button = new He.Button ("", "") {
            label = _("Use"),
            is_fill = true,
            valign = Gtk.Align.CENTER
        };
        use_button.clicked.connect (() => {
            history.active = false;
            entry.get_internal_entry ().set_text (entry_item.result);
            entry.get_internal_entry ().grab_focus ();
        });

        var delete_button = new He.Button ("", "") {
            icon = "user-trash-symbolic",
            is_textual = true,
            valign = Gtk.Align.CENTER
        };
        delete_button.clicked.connect (() => {
            calc_history.remove_entry (index);
        });

        button_box.append (delete_button);
        button_box.append (use_button);

        row_box.append (expr_label);
        row_box.append (result_label);
        row_box.append (button_box);
        row_box.add_css_class ("mini-content-block");

        return row_box;
    }
}
