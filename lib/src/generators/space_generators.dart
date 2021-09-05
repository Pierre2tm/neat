import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:neat/src/anotations.dart';

import 'utils.dart';

class SpaceWidgetGenerator {
  static String tryGenerate(
    VariableElement element,
    NeatAnotation defaultConfig,
  ) {
    if (element.isPublic &&
        element.isStatic &&
        element.isConst &&
        (element.type.isDartCoreList || element.type.isDartCoreMap)) {
      //TODO: config overriding

      if (element.type.isDartCoreList) {
        final list = Utils.tryConvertToListDouble(element);
        return _generateFromList(element.displayName, list, defaultConfig);
      } else if (element.type.isDartCoreMap) {
        final map = Utils.tryConvertToMapStringDouble(element);
        return _generateFromMap(element.displayName, map, defaultConfig);
      }
    }
    throw ("Fields anotated with nt_space must be public static const List<double> or public static const Map<String, double>");
  }

  static String _generateFromList(
    String varName,
    List<double> list,
    NeatAnotation meta,
  ) {
    final base = Utils.varNameToClassBaseFormat(varName);
    return list
        .asMap()
        .entries
        .map((MapEntry<int, double> entry) => _generateCode(
              '$base${entry.key + 1}',
              entry.value,
            ))
        .toList()
        .join("\n");
  }

  static String _generateFromMap(
    String varName,
    Map<String, double> map,
    NeatAnotation meta,
  ) {
    final base = Utils.varNameToClassBaseFormat(varName);
    return map.entries
        .map((MapEntry<String, double> entry) => _generateCode(
              '$base${Utils.capitalizeFirstChar(entry.key)}',
              entry.value,
            ))
        .toList()
        .join("\n");
  }

  static String _generateCode(
    String className,
    double space,
  ) {
    final widgetCode = Class(
      (b) => b
        ..name = className
        ..extend = refer('StatelessWidget')
        ..constructors.addAll([
          Constructor(
            (c) => c
              ..initializers.addAll([
                Code("width = ${space.toStringAsFixed(0)}"),
                Code("height = ${space.toStringAsFixed(0)}")
              ])
              ..constant = true,
          ),
          Constructor(
            (c) => c
              ..name = "w"
              ..initializers.addAll([
                Code("width = ${space.toStringAsFixed(0)}"),
                Code("height = 0"),
              ])
              ..constant = true,
          ),
          Constructor(
            (c) => c
              ..name = "h"
              ..initializers.addAll([
                Code("width = 0"),
                Code("height = ${space.toStringAsFixed(0)}"),
              ])
              ..constant = true,
          ),
        ])
        ..fields.addAll([
          Field(
            (f) => f
              ..name = "width"
              ..modifier = FieldModifier.final$
              ..type = refer("double"),
          ),
          Field(
            (f) => f
              ..name = "height"
              ..modifier = FieldModifier.final$
              ..type = refer("double"),
          )
        ])
        ..methods.add(
          Method(
            (m) => m
              ..annotations.add(refer("override"))
              ..returns = refer('Widget')
              ..name = "build"
              ..body = const Code(
                "return SizedBox(width: width, height: height);",
              )
              ..requiredParameters.add(
                Parameter(
                  (p) => p
                    ..type = refer("BuildContext")
                    ..name = "context",
                ),
              ),
          ),
        ),
    );
    final emitter = DartEmitter();
    return '${widgetCode.accept(emitter)}';
  }
}