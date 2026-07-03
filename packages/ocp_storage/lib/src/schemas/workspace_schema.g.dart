// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_schema.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWorkspaceSchemaCollection on Isar {
  IsarCollection<WorkspaceSchema> get workspaceSchemas => this.collection();
}

const WorkspaceSchemaSchema = CollectionSchema(
  name: r'WorkspaceSchema',
  id: 3734812713027947311,
  properties: {
    r'assignedDeviceIds': PropertySchema(
      id: 0,
      name: r'assignedDeviceIds',
      type: IsarType.stringList,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'settingsJson': PropertySchema(
      id: 3,
      name: r'settingsJson',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 4,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'workspaceId': PropertySchema(
      id: 5,
      name: r'workspaceId',
      type: IsarType.string,
    )
  },
  estimateSize: _workspaceSchemaEstimateSize,
  serialize: _workspaceSchemaSerialize,
  deserialize: _workspaceSchemaDeserialize,
  deserializeProp: _workspaceSchemaDeserializeProp,
  idName: r'id',
  indexes: {
    r'workspaceId': IndexSchema(
      id: 4360577223095013563,
      name: r'workspaceId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'workspaceId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _workspaceSchemaGetId,
  getLinks: _workspaceSchemaGetLinks,
  attach: _workspaceSchemaAttach,
  version: '3.1.0+1',
);

int _workspaceSchemaEstimateSize(
  WorkspaceSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assignedDeviceIds.length * 3;
  {
    for (var i = 0; i < object.assignedDeviceIds.length; i++) {
      final value = object.assignedDeviceIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.settingsJson.length * 3;
  bytesCount += 3 + object.workspaceId.length * 3;
  return bytesCount;
}

void _workspaceSchemaSerialize(
  WorkspaceSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.assignedDeviceIds);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.name);
  writer.writeString(offsets[3], object.settingsJson);
  writer.writeDateTime(offsets[4], object.updatedAt);
  writer.writeString(offsets[5], object.workspaceId);
}

WorkspaceSchema _workspaceSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkspaceSchema();
  object.assignedDeviceIds = reader.readStringList(offsets[0]) ?? [];
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.name = reader.readString(offsets[2]);
  object.settingsJson = reader.readString(offsets[3]);
  object.updatedAt = reader.readDateTime(offsets[4]);
  object.workspaceId = reader.readString(offsets[5]);
  return object;
}

P _workspaceSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _workspaceSchemaGetId(WorkspaceSchema object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _workspaceSchemaGetLinks(WorkspaceSchema object) {
  return [];
}

void _workspaceSchemaAttach(
    IsarCollection<dynamic> col, Id id, WorkspaceSchema object) {
  object.id = id;
}

extension WorkspaceSchemaByIndex on IsarCollection<WorkspaceSchema> {
  Future<WorkspaceSchema?> getByWorkspaceId(String workspaceId) {
    return getByIndex(r'workspaceId', [workspaceId]);
  }

  WorkspaceSchema? getByWorkspaceIdSync(String workspaceId) {
    return getByIndexSync(r'workspaceId', [workspaceId]);
  }

  Future<bool> deleteByWorkspaceId(String workspaceId) {
    return deleteByIndex(r'workspaceId', [workspaceId]);
  }

  bool deleteByWorkspaceIdSync(String workspaceId) {
    return deleteByIndexSync(r'workspaceId', [workspaceId]);
  }

  Future<List<WorkspaceSchema?>> getAllByWorkspaceId(
      List<String> workspaceIdValues) {
    final values = workspaceIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'workspaceId', values);
  }

  List<WorkspaceSchema?> getAllByWorkspaceIdSync(
      List<String> workspaceIdValues) {
    final values = workspaceIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'workspaceId', values);
  }

  Future<int> deleteAllByWorkspaceId(List<String> workspaceIdValues) {
    final values = workspaceIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'workspaceId', values);
  }

  int deleteAllByWorkspaceIdSync(List<String> workspaceIdValues) {
    final values = workspaceIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'workspaceId', values);
  }

  Future<Id> putByWorkspaceId(WorkspaceSchema object) {
    return putByIndex(r'workspaceId', object);
  }

  Id putByWorkspaceIdSync(WorkspaceSchema object, {bool saveLinks = true}) {
    return putByIndexSync(r'workspaceId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByWorkspaceId(List<WorkspaceSchema> objects) {
    return putAllByIndex(r'workspaceId', objects);
  }

  List<Id> putAllByWorkspaceIdSync(List<WorkspaceSchema> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'workspaceId', objects, saveLinks: saveLinks);
  }
}

extension WorkspaceSchemaQueryWhereSort
    on QueryBuilder<WorkspaceSchema, WorkspaceSchema, QWhere> {
  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WorkspaceSchemaQueryWhere
    on QueryBuilder<WorkspaceSchema, WorkspaceSchema, QWhereClause> {
  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterWhereClause>
      workspaceIdEqualTo(String workspaceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'workspaceId',
        value: [workspaceId],
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterWhereClause>
      workspaceIdNotEqualTo(String workspaceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workspaceId',
              lower: [],
              upper: [workspaceId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workspaceId',
              lower: [workspaceId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workspaceId',
              lower: [workspaceId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'workspaceId',
              lower: [],
              upper: [workspaceId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension WorkspaceSchemaQueryFilter
    on QueryBuilder<WorkspaceSchema, WorkspaceSchema, QFilterCondition> {
  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedDeviceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assignedDeviceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assignedDeviceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assignedDeviceIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assignedDeviceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assignedDeviceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assignedDeviceIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assignedDeviceIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assignedDeviceIds',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assignedDeviceIds',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'assignedDeviceIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'assignedDeviceIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'assignedDeviceIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'assignedDeviceIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'assignedDeviceIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      assignedDeviceIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'assignedDeviceIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'settingsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'settingsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'settingsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'settingsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      settingsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'settingsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workspaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'workspaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'workspaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'workspaceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'workspaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'workspaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'workspaceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'workspaceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'workspaceId',
        value: '',
      ));
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterFilterCondition>
      workspaceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'workspaceId',
        value: '',
      ));
    });
  }
}

extension WorkspaceSchemaQueryObject
    on QueryBuilder<WorkspaceSchema, WorkspaceSchema, QFilterCondition> {}

extension WorkspaceSchemaQueryLinks
    on QueryBuilder<WorkspaceSchema, WorkspaceSchema, QFilterCondition> {}

extension WorkspaceSchemaQuerySortBy
    on QueryBuilder<WorkspaceSchema, WorkspaceSchema, QSortBy> {
  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      sortBySettingsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsJson', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      sortBySettingsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsJson', Sort.desc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      sortByWorkspaceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workspaceId', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      sortByWorkspaceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workspaceId', Sort.desc);
    });
  }
}

extension WorkspaceSchemaQuerySortThenBy
    on QueryBuilder<WorkspaceSchema, WorkspaceSchema, QSortThenBy> {
  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      thenBySettingsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsJson', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      thenBySettingsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'settingsJson', Sort.desc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      thenByWorkspaceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workspaceId', Sort.asc);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QAfterSortBy>
      thenByWorkspaceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'workspaceId', Sort.desc);
    });
  }
}

extension WorkspaceSchemaQueryWhereDistinct
    on QueryBuilder<WorkspaceSchema, WorkspaceSchema, QDistinct> {
  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QDistinct>
      distinctByAssignedDeviceIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assignedDeviceIds');
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QDistinct>
      distinctBySettingsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'settingsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<WorkspaceSchema, WorkspaceSchema, QDistinct>
      distinctByWorkspaceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'workspaceId', caseSensitive: caseSensitive);
    });
  }
}

extension WorkspaceSchemaQueryProperty
    on QueryBuilder<WorkspaceSchema, WorkspaceSchema, QQueryProperty> {
  QueryBuilder<WorkspaceSchema, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WorkspaceSchema, List<String>, QQueryOperations>
      assignedDeviceIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assignedDeviceIds');
    });
  }

  QueryBuilder<WorkspaceSchema, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<WorkspaceSchema, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<WorkspaceSchema, String, QQueryOperations>
      settingsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'settingsJson');
    });
  }

  QueryBuilder<WorkspaceSchema, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<WorkspaceSchema, String, QQueryOperations>
      workspaceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'workspaceId');
    });
  }
}
