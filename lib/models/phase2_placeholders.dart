/// Modelos estruturais reservados para a Fase 2 do DER (Rebanhos e Animais).
/// Na Fase 1 não há CRUD nem telas ativas para essas entidades.
class HerdRef {
  const HerdRef({
    required this.id,
    required this.farmId,
    required this.name,
    required this.species,
  });

  final String id;
  final String farmId;
  final String name;
  final String species;
}

class AnimalRef {
  const AnimalRef({
    required this.id,
    this.herdId,
    required this.codeTag,
    required this.species,
  });

  final String id;
  final String? herdId;
  final String codeTag;
  final String species;
}
