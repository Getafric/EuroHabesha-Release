/// UI visibility only. Every callable keeps its independent server authorization.
bool showPrivateStripeTools({
  required bool signedIn,
  required bool anonymous,
  required bool verified,
  required String? email,
}) =>
    signedIn &&
    !anonymous &&
    verified &&
    email?.trim().toLowerCase() == 'getafricshow1@gmail.com';
