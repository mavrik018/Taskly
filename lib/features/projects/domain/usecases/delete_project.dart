import '../repositories/project_repository.dart';

class DeleteProject {
  final ProjectRepository _repository;

  DeleteProject(this._repository);

  Future<int> call(int id) {
    return _repository.deleteProject(id);
  }
}
