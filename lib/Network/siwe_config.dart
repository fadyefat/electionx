import 'package:reown_appkit/reown_appkit.dart';

SIWEConfig buildSIWEConfig() {
  return SIWEConfig(
    getNonce: () async => SIWEUtils.generateNonce(),
    getMessageParams: () async => SIWEMessageArgs(
      domain: 'electionx.app', // ✅ Replace with your real domain
      uri: 'https://electionx.app', // ✅ Your app URI
      statement: 'Sign in to ElectionX',
      methods: MethodsConstants.allMethods,
    ),
    createMessage: (args) => SIWEUtils.formatMessage(args),

    verifyMessage: (args) async {
      // TODO: Implement real message verification (e.g., via backend)
      return true;
    },

    getSession: () async {
      // TODO: Implement session persistence
      return null;
    },

    signOut: () async {
      // TODO: Implement session clearing
      return true;
    },

    onSignIn: (session) {
      print("✅ Signed in as ${session.address}");
    },

    onSignOut: () {
      print("👋 Signed out");
    },
  );
}
