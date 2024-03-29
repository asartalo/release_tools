import 'package:conventional/conventional.dart';
import 'exec.dart';

class GitExecException implements Exception {
  final String message;
  GitExecException(this.message);
}

abstract class GitExec {
  factory GitExec(Exec executor) => _GitExec(executor);
  Future<List<Commit>> commits({String? from});
  Future<String> hashForTag(String tag);
  Future<String> firstHash();
  Future<String> lsRemoteTag({String tag = '', String remote = 'origin'});
}

class _GitExec implements GitExec {
  final Exec executor;

  _GitExec(this.executor);

  @override
  Future<List<Commit>> commits({String? from}) async {
    from ??= await firstHash();
    final logs = _throwOnFail(
      await _execute(
        'git',
        '--no-pager log $from..HEAD --no-decorate'.split(' '),
      ),
    );
    return Commit.parseCommits(logs);
  }

  @override
  Future<String> hashForTag(String tag) async {
    return _throwOnFail(
      await _execute(
        'git',
        'rev-parse $tag^{}'.split(' '),
      ),
    );
  }

  @override
  Future<String> firstHash() async {
    return _throwOnFail(
      await _execute(
        'git',
        'rev-list --max-parents=0 HEAD'.split(' '),
      ),
    );
  }

  Future<Execution> _execute(String cmd, List<String> args) {
    return executor.execute(cmd, args);
  }

  String _throwOnFail(Execution result) {
    if (!result.success) {
      throw GitExecException(result.output);
    }
    return result.output;
  }

  @override
  Future<String> lsRemoteTag({
    String tag = '',
    String remote = 'origin',
  }) async {
    final args = ['ls-remote', '-q', '--tags', remote];
    if (tag.isNotEmpty) {
      args.add(tag);
    }
    return _throwOnFail(
      await _execute(
        'git',
        args,
      ),
    );
  }
}

class StubGitExec implements GitExec {
  List<Commit> commitsResponse = [];
  String? commitsFrom;
  String lsRemoteTagResponse = '';
  Map<String, String> lsRemoteTagArgs = {};

  @override
  Future<List<Commit>> commits({String? from}) async {
    commitsFrom = from;
    return commitsResponse;
  }

  @override
  Future<String> firstHash() {
    // TODO: implement getFirstHash
    throw UnimplementedError();
  }

  @override
  Future<String> hashForTag(String tag) {
    // TODO: implement getHashForTag
    throw UnimplementedError();
  }

  @override
  Future<String> lsRemoteTag({
    String tag = '',
    String remote = 'origin',
  }) async {
    lsRemoteTagArgs = {
      'tag': tag,
      'remote': remote,
    };
    return lsRemoteTagResponse;
  }
}
