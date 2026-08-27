package de.lucadmin.luqa

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not FlutterActivity: Health Connect's permission
// contract goes through registerForActivityResult, which needs a FragmentActivity
// host on Android 14+.
class MainActivity : FlutterFragmentActivity()
