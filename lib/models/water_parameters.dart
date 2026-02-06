class PhysicalChemicalModel {
  final double ph;
  final double ec;
  final double temperature;
  final double tds;
  final double turbidity;
  final double tss;
  final double dissolvedOxygen;
  final double orp;
  final double waterPercent;
  final double liquidChlorineLevel;
  final double freeChlorine;
  final double totalAlkalinity;
  final double totalHardness;

  PhysicalChemicalModel({
    this.ph = 0.0,
    this.ec = 0.0,
    this.temperature = 0.0,
    this.tds = 0.0,
    this.turbidity = 0.0,
    this.tss = 0.0,
    this.dissolvedOxygen = 0.0,
    this.orp = 0.0,
    this.waterPercent = 0.0,
    this.liquidChlorineLevel = 0.0,
    this.freeChlorine = 0.0,
    this.totalAlkalinity = 0.0,
    this.totalHardness = 0.0,
  });

  factory PhysicalChemicalModel.fromJson(Map<String, dynamic> json) {
    return PhysicalChemicalModel(
      ph: double.tryParse(json['pH']?.toString() ?? "0") ?? 0.0,
      ec: double.tryParse(json['EC']?.toString() ?? "0") ?? 0.0,
      tds: double.tryParse(json['TDS']?.toString() ?? "0") ?? 0.0,
      turbidity: double.tryParse(json['Turbidity']?.toString() ?? "0") ?? 0.0,
      dissolvedOxygen: double.tryParse(json['DO']?.toString() ?? "0") ?? 0.0,
      // Add other fields if they exist in JSON
    );
  }
}

class HealthAestheticModel {
  final double eColi;
  final double totalColiforms;
  final double fecalColiforms;
  final double fluoride;
  final double residualChlorine;
  final double freeChlorine;

  HealthAestheticModel({
    this.eColi = 0.0,
    this.totalColiforms = 0.0,
    this.fecalColiforms = 0.0,
    this.fluoride = 0.0,
    this.residualChlorine = 0.0,
    this.freeChlorine = 0.0,
  });

  double get fluorideMgL => fluoride / 1000.0;
}

class MetalsModel {
  final double iron;
  final double lead;
  final double arsenic;

  MetalsModel({this.iron = 0.0, this.lead = 0.0, this.arsenic = 0.0});

  double get ironMgL => iron / 1000.0;
  double get leadMgL => lead / 1000.0;
}

class IonicFeatureModel {
  final double ca;
  final double no3;
  final double mg;

  IonicFeatureModel({this.ca = 0.0, this.no3 = 0.0, this.mg = 0.0});

  factory IonicFeatureModel.fromJson(Map<String, dynamic> json) {
    return IonicFeatureModel(
      ca: double.tryParse(json['Ca']?.toString() ?? "0") ?? 0.0,
      no3: double.tryParse(json['No3']?.toString() ?? "0") ?? 0.0,
      mg: double.tryParse(json['Mg']?.toString() ?? "0") ?? 0.0,
    );
  }
}
