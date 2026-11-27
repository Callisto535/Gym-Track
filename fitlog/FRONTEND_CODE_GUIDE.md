# FitLog frontend code guide

This guide explains the Dart source in `lib/` and helps you find the code behind
the app's visible controls. The generated `build/web/flutter.js` file is compiled
output; edit and explain the Dart source instead.

Line references below refer to the current source files. A blank line is only a
visual separator. In Flutter widget trees, an opening `(` starts a widget or
configuration, named arguments such as `child:` set its properties, and closing
`),`, `]`, or `}` end the corresponding call, list, or code block. Repeated
`const`, `TextStyle`, `EdgeInsets`, and `BorderRadius` lines configure immutable
widgets, colors, spacing, text appearance, and rounded corners.

## Find a button or screen quickly

| What you see | Source location | What happens |
| --- | --- | --- |
| Five-second FitLog splash/logo | [`lib/screens/splash_screen.dart`](lib/screens/splash_screen.dart), around lines 13-24 | Shows the FitLog mark, then opens the login page after five seconds. |
| Username and password fields | [`lib/screens/login_screen.dart`](lib/screens/login_screen.dart), around lines 76-124 | Collects credentials and validates that both fields are filled. |
| LOG IN button | [`lib/screens/login_screen.dart`](lib/screens/login_screen.dart), around lines 127-137 | Accepts username `Fitlog` (case-insensitive) with password `123`, then opens the app. |
| Bottom Home / Workout / History navigation | [`lib/main.dart`](lib/main.dart), `MainScreen`'s `build`, around lines 148-171 | The selected index changes; Home reloads workout data. |
| Workout category chips | [`lib/screens/workout_screen.dart`](lib/screens/workout_screen.dart), `WorkoutScreen`'s `build`, around lines 317-342 | `onPressed` updates `selectedCategory`; the list is filtered to that category. |
| Add Exercise button | [`lib/screens/workout_screen.dart`](lib/screens/workout_screen.dart), around lines 345-360 | Calls `_openAddForm`, then posts the returned exercise to the backend. |
| Edit icon on a workout | [`lib/screens/workout_screen.dart`](lib/screens/workout_screen.dart), around lines 414-423 | Calls `_openEditForm`; a returned edit is sent with an HTTP PUT. |
| Delete icon and confirmation dialog | [`lib/screens/workout_screen.dart`](lib/screens/workout_screen.dart), around lines 224-291 and 425-434 | Asks for confirmation, then sends an HTTP DELETE if confirmed. |
| Try Again on the Home error screen | [`lib/screens/home_screen.dart`](lib/screens/home_screen.dart), around lines 186-208 | Calls the `onRefresh` callback supplied by `MainScreen`. |
| Pull down to refresh Home | [`lib/screens/home_screen.dart`](lib/screens/home_screen.dart), around lines 173-177 or 226-230 | Runs `_refreshAll`, which reloads workouts and news. |
| Category dropdown and exercise fields | [`lib/screens/exercise_form_screen.dart`](lib/screens/exercise_form_screen.dart), around lines 116-220 | Lets the user enter or change the exercise data. |
| Workout date field / calendar icon | [`lib/screens/exercise_form_screen.dart`](lib/screens/exercise_form_screen.dart), around lines 209-219 | Opens `_chooseDate` and updates the displayed date. |
| Save / Save Changes button | [`lib/screens/exercise_form_screen.dart`](lib/screens/exercise_form_screen.dart), around lines 222-231 | Validates the form and returns an `Exercise` to WorkoutScreen. |
| Fitness-news link | [`lib/screens/home_screen.dart`](lib/screens/home_screen.dart), `_NewsArticleCard` around lines 470-510 | Shows the article URL and opens it in the browser when tapped. |

## Dart concepts used throughout

- `import` makes another Dart library available to this file.
- `class` defines a widget, model, or helper type. Names beginning with `_` are
  private to their Dart library/file.
- `final` means a variable is assigned once; `const` is a compile-time constant
  and can help Flutter reuse immutable widgets.
- `StatefulWidget` is used when a screen's displayed values can change.
  `StatelessWidget` is used when the widget only displays the data it receives.
- `build(BuildContext context)` describes the widget tree Flutter should show.
  `context` locates app services and navigation information in that tree.
- `setState(() { ... })` changes state and tells Flutter to rebuild the affected
  screen.
- `async`, `Future`, and `await` support work that finishes later, such as HTTP
  requests or opening another screen.
- `Navigator.push` opens another screen; `Navigator.pop(context, value)` closes
  it and can return a result to the screen that opened it.
- `mounted` checks that a stateful screen still exists before updating it after
  an asynchronous operation.
- `onPressed`, `onTap`, and `onRefresh` are callbacks: functions Flutter runs
  when the user interacts with a control.
- Named routes such as `/splash`, `/login`, and `/main` let the app navigate
  between screens without importing those screens into each other.

## `lib/main.dart` — app setup, shared workout data, and navigation

- Lines 1-12 import Flutter's Material widgets, app configuration, all screens,
  the exercise model, JSON decoding, and the HTTP client.
- Lines 14-16 define `main`, the Dart program entry point. `runApp` starts
  Flutter with the root `MyApp` widget.
- Lines 18-53 define `MyApp`, a stateless root widget. Its constructor accepts
  Flutter's optional `key`; `build` returns the `MaterialApp` that sets the app
  title, dark theme, lime accent, app-bar colors, and card appearance. Its
  `initialRoute` shows `/splash` first, and the route map connects `/splash`,
  `/login`, and `/main` to their corresponding screens.
- Lines 56-61 define `MainScreen` as a stateful widget. Its `createState`
  connects the widget to `_MainScreenState`, where changing data is stored.
- Lines 63-69 hold that state: `_selectedIndex` chooses the current tab,
  `_apiUrl` builds the `/workouts` endpoint, `_exercises` stores decoded workout
  records, `_isLoading` controls the loading indicator, and `_errorMessage`
  carries a user-facing load error.
- Lines 72-76 run `initState` once when the screen is created. Calling
  `_fetchWorkouts` there loads the workouts as the app starts.
- Lines 77-115 implement `_fetchWorkouts`. It checks `mounted`, shows loading
  state and clears an old error, sends an HTTP GET, and handles the response.
  A 200 response is JSON-decoded and converted to `Exercise` objects; another
  status shows a status-code error. A connection/decoding exception shows a
  backend-connection message. `setState` updates what the screen displays.
- Lines 117-127 define `_addExercise`, `_editExercise`, and `_deleteExercise`.
  Each currently refreshes the shared workout list after a change made on the
  Workout screen; the parameters identify the changed record but are not used
  in these refresh-only implementations.
- Lines 130-147 build a list of the Home, Workout, and History screens and show
  the screen whose index is selected. The workout screen receives callbacks;
  History receives the shared exercises.
- Lines 148-171 build the bottom navigation bar. `currentIndex` highlights the
  selected tab, each item supplies its icon and label, and `onTap` updates the
  index. When the tapped index is Home (`0`), workouts are fetched again.
- The remaining lines in the file close the widget constructors, lists, and
  class/method blocks described above.

## `lib/screens/splash_screen.dart` — five-second startup screen

- Lines 1-2 import Flutter widgets and the reusable FitLog logo.
- Lines 4-9 define `SplashScreen` as a stateful screen so it can schedule the
  transition to login.
- Lines 11-21 start a five-second timer in `initState`. If the screen is still
  mounted when the timer ends, `pushReplacementNamed('/login')` replaces it
  with the login page.
- Lines 23-25 show the FitLog logo centered on the splash screen.

## `lib/screens/login_screen.dart` — simple demo login

- Lines 1-2 import Flutter widgets and the reusable FitLog logo.
- Lines 4-9 define the stateful login page.
- Lines 11-24 store the fixed demo credentials, form key, text controllers, and
  password visibility state. The username comparison ignores letter case; the
  password must match exactly.
- Lines 27-45 validate the form, show an error SnackBar for incorrect
  credentials, and navigate to `/main` after a successful login.
- Lines 48-150 build the logo, username and password fields, password
  visibility button, validation messages, and LOG IN button.
- Lines 20-25 dispose the text controllers when the login screen is removed.

These credentials are hardcoded for this simple demonstration only; this is
not production authentication and should not protect real user data.

## `lib/widgets/fitlog_logo.dart` — reusable FitLog mark

- Line 1 imports Flutter widgets.
- Lines 3-36 create the logo from a lime rounded square, fitness-center icon,
  and FitLog wordmark. The splash and login screens share this widget.

## `lib/config/api_config.dart` — backend base address

- Line 1 declares the `ApiConfig` helper class.
- Lines 2-5 define a compile-time `baseUrl`. Flutter can receive an
  `API_BASE_URL` value at build/run time; if none is supplied, the app uses
  `http://localhost:3000`.
- Line 6 closes the class. Screens append endpoint paths such as `/workouts`
  and `/news` to this base address.

## `lib/models/exercise.dart` — workout data and JSON conversion

- Line 1 declares the `Exercise` model class.
- Lines 2-9 declare its immutable fields: record ID, exercise name, category,
  weight, sets, reps, and display date. Their types describe the kind of value
  each field holds.
- Lines 11-18 define the constructor. `required` means callers must supply
  every field when creating an `Exercise`.
- Lines 20-39 define `Exercise.fromJson`, a factory that converts a backend JSON
  map into an `Exercise`.
- Lines 21-28 read `workout_date` when it is present, take its first ten
  characters, split the `YYYY-MM-DD` form, and change it to `DD/MM/YYYY` when
  the split has three parts.
- Lines 30-38 read the remaining JSON fields and parse text/numeric values into
  the model's declared types. Line 39 closes the factory; line 40 closes the
  class.

## `lib/models/news_article.dart` — fitness-news data and JSON conversion

- Line 1 declares the `NewsArticle` model.
- Lines 2-4 declare the three values the UI displays: title, summary, and link.
- Lines 6-10 define a constructor requiring those three values.
- Lines 12-18 define `NewsArticle.fromJson`, which reads those values from the
  backend JSON and converts them to strings. Missing values become empty strings.
- Line 19 closes the model class.

For local backend setup, put the GNews key in `fitlog_api/.env` as
`GNEWS_API_KEY=your_key`. The Flutter app calls the backend's `/news` route, so
the GNews key does not belong in Flutter source code.

If GNews is unavailable, the backend serves the three saved entries in
[`../fitlog_api/news_fallback.json`](../fitlog_api/news_fallback.json). The
response is marked `fallback`, and Home displays its message above the articles
so saved references are distinguishable from live news.

## `lib/screens/workout_screen.dart` — workout list and add/edit/delete actions

- Lines 1-8 import Flutter widgets, API configuration, the Exercise model, the
  form screen, JSON support, and the HTTP package.
- Lines 10-24 define `WorkoutScreen`. Its three required callbacks (`onAdd`,
  `onEdit`, `onDelete`) let the parent refresh shared data after a change.
- Lines 26-40 store this screen's state: the workouts endpoint, the five
  categories, currently selected category, locally loaded workouts, loading
  status, and an error message.
- Lines 42-46 run `_fetchWorkouts` when the screen is first created.
- Lines 48-84 fetch workouts with HTTP GET. The response is decoded into
  `Exercise` objects on status 200; other statuses and exceptions update the
  error/loading state. The `mounted` checks avoid updating a screen that has
  already been closed.
- Lines 86-95 implement `_openAddForm`. `Navigator.push` displays
  `ExerciseFormScreen`; after it closes, a non-null returned exercise is sent
  to `_createWorkout`.
- Lines 97-151 implement `_createWorkout`. It converts the displayed date back
  to the API's `YYYY-MM-DD` format, sends the exercise fields as JSON in an HTTP
  POST, handles success/error responses, refreshes the list and parent state,
  then displays a SnackBar result.
- Lines 153-164 implement `_openEditForm`. It opens the form prefilled with the
  selected exercise and calls `_updateWorkout` if the form returns an edited
  value.
- Lines 166-222 implement `_updateWorkout`. It formats the date, sends an HTTP
  PUT to `/workouts/<id>`, refreshes data on success, and shows a SnackBar for
  success, not-found, server, or connection errors.
- Lines 224-256 implement `_deleteExercise`, the confirmation dialog shown
  before a workout is removed. Cancel returns `false`; Delete returns `true`.
  Only a true result continues to `_deleteWorkout`.
- Lines 258-293 implement `_deleteWorkout`. It sends HTTP DELETE to
  `/workouts/<id>`, reloads data after a successful response, notifies the
  parent, and reports success or errors using a SnackBar.
- Lines 295-305 begin `build`. The `filteredExercises` list keeps only records
  matching `selectedCategory`. A `Scaffold` supplies the Workout app bar and
  screen body.
- Lines 306-344 construct the body layout and category selector. Each category
  becomes a horizontally scrollable button; tapping one updates
  `selectedCategory`, and the selected one uses the lime color.
- Lines 345-361 define the Add Exercise button. Its `onPressed` points to
  `_openAddForm`; the icon, label, and style determine what the user sees.
- Lines 362-393 choose the content below the controls: a spinner while loading,
  an error and Try Again button on failure, or a no-exercises message when the
  selected category is empty.
- Lines 394-443 build the workout list. `ListView.builder` creates one card per
  filtered exercise; each card shows the exercise name, weight, sets, and reps.
  Its edit icon calls `_openEditForm`; its delete icon calls
  `_deleteExercise`. The remaining lines close the widget tree and class.

## `lib/screens/exercise_form_screen.dart` — add/edit exercise form

- Lines 1-2 import Flutter widgets and the Exercise model.
- Lines 4-11 define `ExerciseFormScreen`, a stateful screen that optionally
  receives an existing exercise. A null exercise means add mode; an existing
  one means edit mode.
- Lines 13-30 define form state. `_formKey` validates all fields; each
  `TextEditingController` reads/writes one text field; `categories` lists the
  available workout categories; `_category` and `_selectedDate` hold the
  current selections.
- Lines 32-54 initialize the form. The date defaults to today. If an exercise
  was passed in, its category/name/numbers are copied into the form; a valid
  `DD/MM/YYYY` date is parsed into a `DateTime`.
- Lines 56-64 dispose every text controller when the screen is removed. This
  releases resources and avoids controller leaks.
- Lines 66-80 implement `_chooseDate`. `showDatePicker` opens the calendar with
  allowed dates from 2020 through 2035. If the user picks a date, `setState`
  stores it and updates the text field.
- Lines 82-86 implement `_formatDate`, padding day and month with zeroes and
  returning `DD/MM/YYYY`.
- Lines 88-102 implement `_saveExercise`. It saves only if form validation
  succeeds, parses the numeric fields, creates an `Exercise` (preserving the
  existing ID in edit mode), and pops this screen while returning that object.
- Lines 104-113 determine whether this is edit mode and create the form screen
  with an app-bar title that says Add or Edit Exercise.
- Lines 114-133 build the category dropdown. Its options come from `categories`;
  choosing one stores it in `_category`.
- Lines 134-148 build the Exercise Name input. Its validator rejects a missing
  value.
- Lines 149-168 build the Weight input. The numeric keyboard is shown; the
  validator requires a parseable weight greater than zero.
- Lines 169-188 build the Sets input and require a positive integer.
- Lines 189-208 build the Reps input and require a positive integer.
- Lines 209-220 build the read-only Workout Date input. Tapping the field opens
  `_chooseDate`; the suffix calendar icon is a visual cue.
- Lines 221-232 build the save button. Its `onPressed` calls `_saveExercise`;
  its text changes between SAVE and SAVE CHANGES based on edit mode.
- Remaining lines close the form layout and class definitions.

## `lib/screens/home_screen.dart` — dashboard, progress, and news

- Lines 1-8 import JSON support, API config, exercise and news models, Flutter
  widgets, HTTP, and URL launching.
- Lines 10-26 define `HomeScreen`. The parent passes in exercises, workout
  loading/error status, and an `onRefresh` callback.
- Lines 28-33 keep the news endpoint, loaded articles, loading status, error
  message, and notice for saved fallback data.
- Lines 36-39 call `_fetchNews` when Home is first created.
- Lines 41-112 implement `_fetchNews`. It shows loading state, sends HTTP GET,
  accepts either live `success` data or explicit `fallback` data, converts up
  to ten entries into `NewsArticle` objects, and reports invalid response,
  server, or connection errors.
- Lines 114-117 implement `_refreshAll`, which awaits the parent's workout
  refresh and then fetches news again.
- Lines 119-137 implement `_openArticle`. It parses and validates an HTTP/HTTPS
  URL, opens it in an external app/browser, and displays a SnackBar if the URL
  is invalid or could not be opened.
- Lines 140-162 calculate dashboard values in `build`: total sets across all
  exercises, today's exercises, today's set total, and the distinct categories
  trained today.
- Lines 163-171 create the Home `Scaffold` and FitLog app bar.
- Lines 172-224 show workout loading/error status and Fitness News together.
  The Try Again button invokes the `onRefresh` callback received from the
  parent, but a workout API failure no longer hides the news feed.
- Lines 226-232 wrap the normal Home content in a `RefreshIndicator`; pulling
  down calls `_refreshAll`. `SingleChildScrollView` allows the dashboard to
  scroll.
- Lines 233-323 build the welcome text and Today's Workout card. The card shows
  today's exercise count, categories, total sets, and either Rest Day or
  Completed.
- Lines 324-348 show Quick Stats using `_SummaryCard` widgets for exercise and
  set totals.
- Lines 350-358 add the Fitness News heading and the news section.
- Lines 365-369 implement `_formatDate`, which produces `DD/MM/YYYY` so
  today's workouts can be compared with the dates stored in each Exercise.
- Lines 371-438 implement `_buildNewsSection`. It returns a loading card, an
  error card with Retry, an empty-state card, or the fallback notice and news
  article cards.
- Lines 440-468 define `_SummaryCard`, a small reusable stat card that shows a
  value and its label.
- Lines 470-510 define `_NewsArticleCard`. It displays the article title,
  summary, and link only. The link button calls `_openArticle` to open the
  original article outside the app; no article photos are loaded.

## `lib/screens/history_screen.dart` — workout history

- Lines 1-2 import Flutter widgets and the Exercise model.
- Lines 4-8 define a stateless `HistoryScreen`; it receives the exercise list
  from its parent and does not fetch or modify the data itself.
- Lines 10-13 build the History `Scaffold` and app bar.
- Lines 14-19 show a "No workout history" message when the list is empty.
- Lines 20-94 use `ListView.builder` to create a card for every exercise. Each
  card shows the date, category, exercise name, weight, sets, and reps. The
  remaining lines close the card/list/widget tree and class.

## Data flow summary for a project demonstration

1. `main.dart` starts the app and initially loads workouts from the backend.
2. The bottom navigation selects Home, Workout, or History.
3. Workout buttons open the form or send create/update/delete requests from
   `workout_screen.dart`.
4. `exercise_form_screen.dart` validates input and returns an `Exercise`; the
   Workout screen sends that data to the API.
5. `Exercise.fromJson` converts workout API records into Dart objects.
   `NewsArticle.fromJson` converts GNews title, description, and URL fields
   (mapped by the backend to title, summary, and link).
6. Home and History display the shared workout data; Home separately loads news
   and opens an article link when a news card is tapped.
