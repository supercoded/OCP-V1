// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_schema.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIdentitySchemaCollection on Isar {
  IsarCollection<IdentitySchema> get identitySchemas => this.collection();
}

const IdentitySchemaSchema = CollectionSchema(
  name: r'IdentitySchema',
  id: -4819907143996704200,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'displayName': PropertySchema(
      id: 1,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'exportMetadata': PropertySchema(
      id: 2,
      name: r'exportMetadata',
      type: IsarType.string,
    ),
    r'identityId': PropertySchema(
      id: 3,
      name: r'identityId',
      type: IsarType.string,
    ),
    r'isActive': PropertySchema(
      id: 4,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _identitySchemaEstimateSize,
  serialize: _identitySchemaSerialize,
  deserialize: _identitySchemaDeserialize,
  deserializeProp: _identitySchemaDeserializeProp,
  idName: r'id',
  indexes: {
    r'identityId': IndexSchema(
      id: 1738616051568895492,
      name: r'identityId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'identityId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _identitySchemaGetId,
  getLinks: _identitySchemaGetLinks,
  attach: _identitySchemaAttach,
  version: '3.1.0+1',
);

int _identitySchemaEstimateSize(
  IdentitySchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.displayName.length * 3;
  {
    final value = object.exportMetadata;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.identityId.length * 3;
  return bytesCount;
}

void _identitySchemaSerialize(
  IdentitySchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.displayName);
  writer.writeString(offsets[2], object.exportMetadata);
  writer.writeString(offsets[3], object.identityId);
  writer.writeBool(offsets[4], object.isActive);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

IdentitySchema _identitySchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IdentitySchema();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.displayName = reader.readString(offsets[1]);
  object.exportMetadata = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.identityId = reader.readString(offsets[3]);
  object.isActive = reader.readBool(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _identitySchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _identitySchemaGetId(IdentitySchema object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _identitySchemaGetLinks(IdentitySchema object) {
  return [];
}

void _identitySchemaAttach(
    IsarCollection<dynamic> col, Id id, IdentitySchema object) {
  object.id = id;
}

extension IdentitySchemaByIndex on IsarCollection<IdentitySchema> {
  Future<IdentitySchema?> getByIdentityId(String identityId) {
    return getByIndex(r'identityId', [identityId]);
  }

  IdentitySchema? getByIdentityIdSync(String identityId) {
    return getByIndexSync(r'identityId', [identityId]);
  }

  Future<bool> deleteByIdentityId(String identityId) {
    return deleteByIndex(r'identityId', [identityId]);
  }

  bool deleteByIdentityIdSync(String identityId) {
    return deleteByIndexSync(r'identityId', [identityId]);
  }

  Future<List<IdentitySchema?>> getAllByIdentityId(
      List<String> identityIdValues) {
    final values = identityIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'identityId', values);
  }

  List<IdentitySchema?> getAllByIdentityIdSync(List<String> identityIdValues) {
    final values = identityIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'identityId', values);
  }

  Future<int> deleteAllByIdentityId(List<String> identityIdValues) {
    final values = identityIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'identityId', values);
  }

  int deleteAllByIdentityIdSync(List<String> identityIdValues) {
    final values = identityIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'identityId', values);
  }

  Future<Id> putByIdentityId(IdentitySchema object) {
    return putByIndex(r'identityId', object);
  }

  Id putByIdentityIdSync(IdentitySchema object, {bool saveLinks = true}) {
    return putByIndexSync(r'identityId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByIdentityId(List<IdentitySchema> objects) {
    return putAllByIndex(r'identityId', objects);
  }

  List<Id> putAllByIdentityIdSync(List<IdentitySchema> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'identityId', objects, saveLinks: saveLinks);
  }
}

extension IdentitySchemaQueryWhereSort
    on QueryBuilder<IdentitySchema, IdentitySchema, QWhere> {
  QueryBuilder<IdentitySchema, IdentitySchema, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IdentitySchemaQueryWhere
    on QueryBuilder<IdentitySchema, IdentitySchema, QWhereClause> {
  QueryBuilder<IdentitySchema, IdentitySchema, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterWhereClause> idBetween(
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterWhereClause>
      identityIdEqualTo(String identityId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'identityId',
        value: [identityId],
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterWhereClause>
      identityIdNotEqualTo(String identityId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'identityId',
              lower: [],
              upper: [identityId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'identityId',
              lower: [identityId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'identityId',
              lower: [identityId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'identityId',
              lower: [],
              upper: [identityId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IdentitySchemaQueryFilter
    on QueryBuilder<IdentitySchema, IdentitySchema, QFilterCondition> {
  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'exportMetadata',
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'exportMetadata',
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exportMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exportMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exportMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exportMetadata',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exportMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exportMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exportMetadata',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exportMetadata',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exportMetadata',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      exportMetadataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exportMetadata',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition> idBetween(
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'identityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'identityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'identityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'identityId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'identityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'identityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'identityId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'identityId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'identityId',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      identityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'identityId',
        value: '',
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      isActiveEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
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

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterFilterCondition>
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
}

extension IdentitySchemaQueryObject
    on QueryBuilder<IdentitySchema, IdentitySchema, QFilterCondition> {}

extension IdentitySchemaQueryLinks
    on QueryBuilder<IdentitySchema, IdentitySchema, QFilterCondition> {}

extension IdentitySchemaQuerySortBy
    on QueryBuilder<IdentitySchema, IdentitySchema, QSortBy> {
  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      sortByExportMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exportMetadata', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      sortByExportMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exportMetadata', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      sortByIdentityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'identityId', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      sortByIdentityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'identityId', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IdentitySchemaQuerySortThenBy
    on QueryBuilder<IdentitySchema, IdentitySchema, QSortThenBy> {
  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      thenByExportMetadata() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exportMetadata', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      thenByExportMetadataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exportMetadata', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      thenByIdentityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'identityId', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      thenByIdentityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'identityId', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension IdentitySchemaQueryWhereDistinct
    on QueryBuilder<IdentitySchema, IdentitySchema, QDistinct> {
  QueryBuilder<IdentitySchema, IdentitySchema, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QDistinct> distinctByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QDistinct>
      distinctByExportMetadata({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exportMetadata',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QDistinct> distinctByIdentityId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'identityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<IdentitySchema, IdentitySchema, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension IdentitySchemaQueryProperty
    on QueryBuilder<IdentitySchema, IdentitySchema, QQueryProperty> {
  QueryBuilder<IdentitySchema, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IdentitySchema, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IdentitySchema, String, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<IdentitySchema, String?, QQueryOperations>
      exportMetadataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exportMetadata');
    });
  }

  QueryBuilder<IdentitySchema, String, QQueryOperations> identityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'identityId');
    });
  }

  QueryBuilder<IdentitySchema, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<IdentitySchema, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
