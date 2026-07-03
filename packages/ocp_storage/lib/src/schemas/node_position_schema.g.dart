// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_position_schema.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetNodePositionSchemaCollection on Isar {
  IsarCollection<NodePositionSchema> get nodePositionSchemas =>
      this.collection();
}

const NodePositionSchemaSchema = CollectionSchema(
  name: r'NodePositionSchema',
  id: 2748185863669977420,
  properties: {
    r'altitude': PropertySchema(
      id: 0,
      name: r'altitude',
      type: IsarType.double,
    ),
    r'heading': PropertySchema(
      id: 1,
      name: r'heading',
      type: IsarType.double,
    ),
    r'lat': PropertySchema(
      id: 2,
      name: r'lat',
      type: IsarType.double,
    ),
    r'lon': PropertySchema(
      id: 3,
      name: r'lon',
      type: IsarType.double,
    ),
    r'nodeId': PropertySchema(
      id: 4,
      name: r'nodeId',
      type: IsarType.string,
    ),
    r'source': PropertySchema(
      id: 5,
      name: r'source',
      type: IsarType.byte,
      enumMap: _NodePositionSchemasourceEnumValueMap,
    ),
    r'speedMps': PropertySchema(
      id: 6,
      name: r'speedMps',
      type: IsarType.double,
    ),
    r'timestamp': PropertySchema(
      id: 7,
      name: r'timestamp',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _nodePositionSchemaEstimateSize,
  serialize: _nodePositionSchemaSerialize,
  deserialize: _nodePositionSchemaDeserialize,
  deserializeProp: _nodePositionSchemaDeserializeProp,
  idName: r'id',
  indexes: {
    r'nodeId_timestamp': IndexSchema(
      id: -2228842719167518668,
      name: r'nodeId_timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'nodeId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _nodePositionSchemaGetId,
  getLinks: _nodePositionSchemaGetLinks,
  attach: _nodePositionSchemaAttach,
  version: '3.1.0+1',
);

int _nodePositionSchemaEstimateSize(
  NodePositionSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.nodeId.length * 3;
  return bytesCount;
}

void _nodePositionSchemaSerialize(
  NodePositionSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.altitude);
  writer.writeDouble(offsets[1], object.heading);
  writer.writeDouble(offsets[2], object.lat);
  writer.writeDouble(offsets[3], object.lon);
  writer.writeString(offsets[4], object.nodeId);
  writer.writeByte(offsets[5], object.source.index);
  writer.writeDouble(offsets[6], object.speedMps);
  writer.writeDateTime(offsets[7], object.timestamp);
}

NodePositionSchema _nodePositionSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NodePositionSchema();
  object.altitude = reader.readDoubleOrNull(offsets[0]);
  object.heading = reader.readDoubleOrNull(offsets[1]);
  object.id = id;
  object.lat = reader.readDouble(offsets[2]);
  object.lon = reader.readDouble(offsets[3]);
  object.nodeId = reader.readString(offsets[4]);
  object.source = _NodePositionSchemasourceValueEnumMap[
          reader.readByteOrNull(offsets[5])] ??
      PositionSource.direct;
  object.speedMps = reader.readDoubleOrNull(offsets[6]);
  object.timestamp = reader.readDateTime(offsets[7]);
  return object;
}

P _nodePositionSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (_NodePositionSchemasourceValueEnumMap[
              reader.readByteOrNull(offset)] ??
          PositionSource.direct) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _NodePositionSchemasourceEnumValueMap = {
  'direct': 0,
  'relayed': 1,
};
const _NodePositionSchemasourceValueEnumMap = {
  0: PositionSource.direct,
  1: PositionSource.relayed,
};

Id _nodePositionSchemaGetId(NodePositionSchema object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _nodePositionSchemaGetLinks(
    NodePositionSchema object) {
  return [];
}

void _nodePositionSchemaAttach(
    IsarCollection<dynamic> col, Id id, NodePositionSchema object) {
  object.id = id;
}

extension NodePositionSchemaQueryWhereSort
    on QueryBuilder<NodePositionSchema, NodePositionSchema, QWhere> {
  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhere>
      anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension NodePositionSchemaQueryWhere
    on QueryBuilder<NodePositionSchema, NodePositionSchema, QWhereClause> {
  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
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

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      nodeIdEqualToAnyTimestamp(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nodeId_timestamp',
        value: [nodeId],
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      nodeIdNotEqualToAnyTimestamp(String nodeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId_timestamp',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId_timestamp',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId_timestamp',
              lower: [nodeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId_timestamp',
              lower: [],
              upper: [nodeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      nodeIdTimestampEqualTo(String nodeId, DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'nodeId_timestamp',
        value: [nodeId, timestamp],
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      nodeIdEqualToTimestampNotEqualTo(String nodeId, DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId_timestamp',
              lower: [nodeId],
              upper: [nodeId, timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId_timestamp',
              lower: [nodeId, timestamp],
              includeLower: false,
              upper: [nodeId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId_timestamp',
              lower: [nodeId, timestamp],
              includeLower: false,
              upper: [nodeId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'nodeId_timestamp',
              lower: [nodeId],
              upper: [nodeId, timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      nodeIdEqualToTimestampGreaterThan(
    String nodeId,
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nodeId_timestamp',
        lower: [nodeId, timestamp],
        includeLower: include,
        upper: [nodeId],
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      nodeIdEqualToTimestampLessThan(
    String nodeId,
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nodeId_timestamp',
        lower: [nodeId],
        upper: [nodeId, timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      nodeIdEqualToTimestampBetween(
    String nodeId,
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'nodeId_timestamp',
        lower: [nodeId, lowerTimestamp],
        includeLower: includeLower,
        upper: [nodeId, upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension NodePositionSchemaQueryFilter
    on QueryBuilder<NodePositionSchema, NodePositionSchema, QFilterCondition> {
  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      altitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'altitude',
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      altitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'altitude',
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      altitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'altitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      altitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'altitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      altitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'altitude',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      altitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'altitude',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      headingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'heading',
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      headingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'heading',
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      headingEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'heading',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      headingGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'heading',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      headingLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'heading',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      headingBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'heading',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
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

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
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

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
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

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      latEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      latGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      latLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      latBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      lonEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lon',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      lonGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lon',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      lonLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lon',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      lonBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lon',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nodeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nodeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nodeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      nodeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nodeId',
        value: '',
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      sourceEqualTo(PositionSource value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      sourceGreaterThan(
    PositionSource value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      sourceLessThan(
    PositionSource value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      sourceBetween(
    PositionSource lower,
    PositionSource upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      speedMpsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'speedMps',
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      speedMpsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'speedMps',
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      speedMpsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speedMps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      speedMpsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speedMps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      speedMpsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speedMps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      speedMpsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speedMps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension NodePositionSchemaQueryObject
    on QueryBuilder<NodePositionSchema, NodePositionSchema, QFilterCondition> {}

extension NodePositionSchemaQueryLinks
    on QueryBuilder<NodePositionSchema, NodePositionSchema, QFilterCondition> {}

extension NodePositionSchemaQuerySortBy
    on QueryBuilder<NodePositionSchema, NodePositionSchema, QSortBy> {
  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByAltitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'altitude', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByAltitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'altitude', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByHeading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heading', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByHeadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heading', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lon', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lon', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortBySpeedMps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedMps', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortBySpeedMpsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedMps', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension NodePositionSchemaQuerySortThenBy
    on QueryBuilder<NodePositionSchema, NodePositionSchema, QSortThenBy> {
  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByAltitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'altitude', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByAltitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'altitude', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByHeading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heading', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByHeadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heading', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lon', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lon', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByNodeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByNodeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nodeId', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenBySpeedMps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedMps', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenBySpeedMpsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedMps', Sort.desc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension NodePositionSchemaQueryWhereDistinct
    on QueryBuilder<NodePositionSchema, NodePositionSchema, QDistinct> {
  QueryBuilder<NodePositionSchema, NodePositionSchema, QDistinct>
      distinctByAltitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'altitude');
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QDistinct>
      distinctByHeading() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'heading');
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QDistinct>
      distinctByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lat');
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QDistinct>
      distinctByLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lon');
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QDistinct>
      distinctByNodeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nodeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QDistinct>
      distinctBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source');
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QDistinct>
      distinctBySpeedMps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speedMps');
    });
  }

  QueryBuilder<NodePositionSchema, NodePositionSchema, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension NodePositionSchemaQueryProperty
    on QueryBuilder<NodePositionSchema, NodePositionSchema, QQueryProperty> {
  QueryBuilder<NodePositionSchema, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<NodePositionSchema, double?, QQueryOperations>
      altitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'altitude');
    });
  }

  QueryBuilder<NodePositionSchema, double?, QQueryOperations>
      headingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'heading');
    });
  }

  QueryBuilder<NodePositionSchema, double, QQueryOperations> latProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lat');
    });
  }

  QueryBuilder<NodePositionSchema, double, QQueryOperations> lonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lon');
    });
  }

  QueryBuilder<NodePositionSchema, String, QQueryOperations> nodeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nodeId');
    });
  }

  QueryBuilder<NodePositionSchema, PositionSource, QQueryOperations>
      sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<NodePositionSchema, double?, QQueryOperations>
      speedMpsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speedMps');
    });
  }

  QueryBuilder<NodePositionSchema, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}
