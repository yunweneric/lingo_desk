/// The repository LingoDesk is published from, in one place.
///
/// Both the landing page's download section and the in-app update check
/// build their URLs from here, so pointing either at a fork is a one-line
/// change.
class GithubRepo {
  const GithubRepo._();

  static const owner = 'yunweneric';
  static const name = 'lingo_desk';
  static const slug = '$owner/$name';

  static const url = 'https://github.com/$slug';
  static const releases = '$url/releases';
  static const actions = '$url/actions';
  static const issues = '$url/issues';
  static const license = '$url/blob/main/LICENSE';
  static const readme = '$url#readme';
  static const api = 'https://api.github.com/repos/$slug';
}
