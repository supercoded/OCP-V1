// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_region_schema.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMapRegionSchemaCollection on Isar {
  IsarCollection<MapRegionSchema> get mapRegionSchemas => this.collection();
}

const MapRegionSchemaSchema = CollectionSchema(
  name: r'MapRegionSchema',
  id: -4404934618796870295,
  properties: {
    r'downloadedAt': PropertySchema(
      id: 0,
      name: r'downloadedAt',
      type: IsarType.dateTime,
    ),
    r'maxLat': PropertySchema(
      id: 1,
      name: r'maxLat',
      type: IsarType.double,
    ),
    r'maxLon': PropertySchema(
      id: 2,
      name: r'maxLon',
      type: IsarType.double,
    ),
    r'maxZoom': PropertySchema(
      id: 3,
      name: r'maxZoom',
      type: IsarType.long,
    ),
    r'minLat': PropertySchema(
      id: 4,
      name: r'minLat',
      type: IsarType.double,
    ),
    r'minLon': PropertySchema(
      id: 5,
      name: r'minLon',
      type: IsarType.double,
    ),
    r'minZoom': PropertySchema(
      id: 6,
      name: r'minZoom',
      type: IsarType.long,
    ),
    r'regionId': PropertySchema(
      id: 7,
      name: r'regionId',
      type: IsarType.string,
    ),
    r'sizeBytes': PropertySchema(
      id: 8,
      name: r'sizeBytes',
      type: IsarType.long,
    ),
    r'storagePath': PropertySchema(
      id: 9,
      name: r'storagePath',
      type: IsarType.string,
    ),
    r'style': PropertySchema(
      id: 10,
      name: r'style',
      type: IsarType.string,
    )
  },
  estimateSize: _mapRegionSchemaEstimateSize,
  serialize: _mapRegionSchemaSerialize,
  deserialize: _mapRegionSchemaDeserialize,
  deserializeProp: _mapRegionSchemaDeserializeProp,
  idName: r'id',
  indexes: {
    r'regionId': IndexSchema(
      id: -3633044038139156791,
      name: r'regionId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'regionId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _mapRegionSchemaGetId,
  getLinks: _mapRegionSchemaGetLinks,
  attach: _mapRegionSchemaAttach,
  version: '3.1.0+1',
);

int _mapRegionSchemaEstimateSize(
  MapRegionSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.regionId.length * 3;
  bytesCount += 3 + object.storagePath.length * 3;
  bytesCount += 3 + object.style.length * 3;
  return bytesCount;
}

void _mapRegionSchemaSerialize(
  MapRegionSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.downloadedAt);
  writer.writeDouble(offsets[1], object.maxLat);
  writer.writeDouble(offsets[2], object.maxLon);
  writer.writeLong(offsets[3], object.maxZoom);
  writer.writeDouble(offsets[4], object.minLat);
  writer.writeDouble(offsets[5], object.minLon);
  writer.writeLong(offsets[6], object.minZoom);
  writer.writeString(offsets[7], object.regionId);
  writer.writeLong(offsets[8], object.sizeBytes);
  writer.writeString(offsets[9], object.storagePath);
  writer.writeString(offsets[10], object.style);
}

MapRegionSchema _mapRegionSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MapRegionSchema();
  object.downloadedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.maxLat = reader.readDouble(offsets[1]);
  object.maxLon = reader.readDouble(offsets[2]);
  object.maxZoom = reader.readLong(offsets[3]);
  object.minLat = reader.readDouble(offsets[4]);
  object.minLon = reader.readDouble(offsets[5]);
  object.minZoom = reader.readLong(offsets[6]);
  object.regionId = reader.readString(offsets[7]);
  object.sizeBytes = reader.readLong(offsets[8]);
  object.storagePath = reader.readString(offsets[9]);
  object.style = reader.readString(offsets[10]);
  return object;
}

P _mapRegionSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _mapRegionSchemaGetId(MapRegionSchema object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mapRegionSchemaGetLinks(MapRegionSchema object) {
  return [];
}

void _mapRegionSchemaAttach(
    IsarCollection<dynamic> col, Id id, MapRegionSchema object) {
  object.id = id;
}

extension MapRegionSchemaByIndex on IsarCollection<MapRegionSchema> {
  Future<MapRegionSchema?> getByRegionId(String regionId) {
    return getByIndex(r'regionId', [regionId]);
  }

  MapRegionSchema? getByRegionIdSync(String regionId) {
    return getByIndexSync(r'regionId', [regionId]);
  }

  Future<bool> deleteByRegionId(String regionId) {
    return deleteByIndex(r'regionId', [regionId]);
  }

  bool deleteByRegionIdSync(String regionId) {
    return deleteByIndexSync(r'regionId', [regionId]);
  }

  Future<List<MapRegionSchema?>> getAllByRegionId(List<String> regionIdValues) {
    final values = regionIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'regionId', values);
  }

  List<MapRegionSchema?> getAllByRegionIdSync(List<String> regionIdValues) {
    final values = regionIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'regionId', values);
  }

  Future<int> deleteAllByRegionId(List<String> regionIdValues) {
    final values = regionIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'regionId', values);
  }

  int deleteAllByRegionIdSync(List<String> regionIdValues) {
    final values = regionIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'regionId', values);
  }

  Future<Id> putByRegionId(MapRegionSchema object) {
    return putByIndex(r'regionId', object);
  }

  Id putByRegionIdSync(MapRegionSchema object, {bool saveLinks = true}) {
    return putByIndexSync(r'regionId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRegionId(List<MapRegionSchema> objects) {
    return putAllByIndex(r'regionId', objects);
  }

  List<Id> putAllByRegionIdSync(List<MapRegionSchema> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'regionId', objects, saveLinks: saveLinks);
  }
}

extension MapRegionSchemaQueryWhereSort
    on QueryBuilder<MapRegionSchema, MapRegionSchema, QWhere> {
  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MapRegionSchemaQueryWhere
    on QueryBuilder<MapRegionSchema, MapRegionSchema, QWhereClause> {
  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterWhereClause>
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

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterWhereClause> idBetween(
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

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterWhereClause>
      regionIdEqualTo(String regionId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'regionId',
        value: [regionId],
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterWhereClause>
      regionIdNotEqualTo(String regionId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'regionId',
              lower: [],
              upper: [regionId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'regionId',
              lower: [regionId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'regionId',
              lower: [regionId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'regionId',
              lower: [],
              upper: [regionId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MapRegionSchemaQueryFilter
    on QueryBuilder<MapRegionSchema, MapRegionSchema, QFilterCondition> {
  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      downloadedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      downloadedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      downloadedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloadedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      downloadedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloadedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
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

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
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

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
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

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxLatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxLatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxLatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxLatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxLat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxLonEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxLon',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxLonGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxLon',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxLonLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxLon',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxLonBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxLon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxZoomEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxZoomGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxZoomLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      maxZoomBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxZoom',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minLatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minLatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minLatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minLat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minLatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minLat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minLonEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minLon',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minLonGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minLon',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minLonLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minLon',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minLonBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minLon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minZoomEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minZoomGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minZoomLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minZoom',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      minZoomBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minZoom',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'regionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'regionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'regionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'regionId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'regionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'regionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'regionId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'regionId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'regionId',
        value: '',
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      regionIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'regionId',
        value: '',
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      sizeBytesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      sizeBytesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      sizeBytesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sizeBytes',
        value: value,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      sizeBytesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sizeBytes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'storagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'storagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'storagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'storagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'storagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'storagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'storagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      storagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'storagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'style',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'style',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'style',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'style',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'style',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'style',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'style',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'style',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'style',
        value: '',
      ));
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterFilterCondition>
      styleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'style',
        value: '',
      ));
    });
  }
}

extension MapRegionSchemaQueryObject
    on QueryBuilder<MapRegionSchema, MapRegionSchema, QFilterCondition> {}

extension MapRegionSchemaQueryLinks
    on QueryBuilder<MapRegionSchema, MapRegionSchema, QFilterCondition> {}

extension MapRegionSchemaQuerySortBy
    on QueryBuilder<MapRegionSchema, MapRegionSchema, QSortBy> {
  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> sortByMaxLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLat', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByMaxLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLat', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> sortByMaxLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLon', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByMaxLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLon', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> sortByMaxZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxZoom', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByMaxZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxZoom', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> sortByMinLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLat', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByMinLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLat', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> sortByMinLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLon', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByMinLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLon', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> sortByMinZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minZoom', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByMinZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minZoom', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByRegionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'regionId', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByRegionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'regionId', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortBySizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortBySizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByStoragePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storagePath', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByStoragePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storagePath', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> sortByStyle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'style', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      sortByStyleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'style', Sort.desc);
    });
  }
}

extension MapRegionSchemaQuerySortThenBy
    on QueryBuilder<MapRegionSchema, MapRegionSchema, QSortThenBy> {
  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> thenByMaxLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLat', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByMaxLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLat', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> thenByMaxLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLon', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByMaxLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxLon', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> thenByMaxZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxZoom', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByMaxZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxZoom', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> thenByMinLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLat', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByMinLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLat', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> thenByMinLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLon', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByMinLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minLon', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> thenByMinZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minZoom', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByMinZoomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minZoom', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByRegionId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'regionId', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByRegionIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'regionId', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenBySizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenBySizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByStoragePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storagePath', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByStoragePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storagePath', Sort.desc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy> thenByStyle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'style', Sort.asc);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QAfterSortBy>
      thenByStyleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'style', Sort.desc);
    });
  }
}

extension MapRegionSchemaQueryWhereDistinct
    on QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct> {
  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct>
      distinctByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadedAt');
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct> distinctByMaxLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxLat');
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct> distinctByMaxLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxLon');
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct>
      distinctByMaxZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxZoom');
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct> distinctByMinLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minLat');
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct> distinctByMinLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minLon');
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct>
      distinctByMinZoom() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minZoom');
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct> distinctByRegionId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'regionId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct>
      distinctBySizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sizeBytes');
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct>
      distinctByStoragePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'storagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MapRegionSchema, MapRegionSchema, QDistinct> distinctByStyle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'style', caseSensitive: caseSensitive);
    });
  }
}

extension MapRegionSchemaQueryProperty
    on QueryBuilder<MapRegionSchema, MapRegionSchema, QQueryProperty> {
  QueryBuilder<MapRegionSchema, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MapRegionSchema, DateTime, QQueryOperations>
      downloadedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadedAt');
    });
  }

  QueryBuilder<MapRegionSchema, double, QQueryOperations> maxLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxLat');
    });
  }

  QueryBuilder<MapRegionSchema, double, QQueryOperations> maxLonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxLon');
    });
  }

  QueryBuilder<MapRegionSchema, int, QQueryOperations> maxZoomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxZoom');
    });
  }

  QueryBuilder<MapRegionSchema, double, QQueryOperations> minLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minLat');
    });
  }

  QueryBuilder<MapRegionSchema, double, QQueryOperations> minLonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minLon');
    });
  }

  QueryBuilder<MapRegionSchema, int, QQueryOperations> minZoomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minZoom');
    });
  }

  QueryBuilder<MapRegionSchema, String, QQueryOperations> regionIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'regionId');
    });
  }

  QueryBuilder<MapRegionSchema, int, QQueryOperations> sizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sizeBytes');
    });
  }

  QueryBuilder<MapRegionSchema, String, QQueryOperations>
      storagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'storagePath');
    });
  }

  QueryBuilder<MapRegionSchema, String, QQueryOperations> styleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'style');
    });
  }
}
