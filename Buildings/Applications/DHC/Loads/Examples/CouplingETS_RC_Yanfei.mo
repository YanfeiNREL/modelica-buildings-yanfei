within Buildings.Applications.DHC.Loads.Examples;
model CouplingETS_RC_Yanfei
  "Example illustrating the coupling of a RC building model to a Energy Transfer Station (ETS) cooling model"
  import Buildings;
  import Buildings.Applications.DHC.EnergyTransferStations.CoolingIndirect;
  extends Modelica.Icons.Example;

  package Medium = Buildings.Media.Water;

  parameter Modelica.SIunits.MassFlowRate mDis_flow_nominal = 0.5
    "Nominal mass flow rate on district-side (primary)";
  parameter Modelica.SIunits.MassFlowRate mBui_flow_nominal = 0.5
    "Nominal mass flow rate on building-side (secondary)";

  parameter Modelica.SIunits.MassFlowRate m1_flow_nominal=0.5 "kg/s";

  parameter Real cp = 4.2 "J/kg-k";

  Buildings.BoundaryConditions.WeatherData.ReaderTMY3
                                            weaDat(
    calTSky=Buildings.BoundaryConditions.Types.SkyTemperatureCalculation.HorizontalRadiation,
    computeWetBulbTemperature=false,
    filNam=Modelica.Utilities.Files.loadResource(
        "modelica://Buildings/Resources/weatherdata/USA_CA_San.Francisco.Intl.AP.724940_TMY3.mos"))
    "Weather data reader"
    annotation (Placement(transformation(extent={{92,16},{72,36}})));

  Buildings.Applications.DHC.Loads.Examples.BaseClasses.RCBuilding building(
      Q_flowCoo_nominal={1000}, Q_flowHea_nominal={2000,1000})
    annotation (Placement(transformation(extent={{58,-28},{84,-2}})));
  Buildings.Fluid.Sources.MassFlowSource_T supHea(
    use_m_flow_in=true,
    nPorts=1,
    use_T_in=true,
    redeclare package Medium = Buildings.Media.Water)
              "Supply for heating water"          annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=0,
        origin={-30,58})));
  Buildings.Fluid.Sources.Boundary_pT sinHea(
    nPorts=1,
    T=couHea.T1_b_nominal,
    redeclare package Medium = Buildings.Media.Water,
    p=300000) "Sink for heating water"
                                      annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=0,
        origin={140,56})));
  Buildings.Applications.DHC.Loads.BaseClasses.HeatingOrCooling couHea(
    flowRegime=building.floRegHeaLoa,
    Q_flow_nominal=building.Q_flowHea_nominal,
    T2_nominal=building.THeaLoa_nominal,
    m_flow2_nominal=building.m_flowHeaLoa_nominal,
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    nLoa=building.nHeaLoa,
    redeclare package Medium = Buildings.Media.Water,
    T1_a_nominal=318.15,
    T1_b_nominal=313.15)
    annotation (Placement(transformation(extent={{30,66},{50,46}})));
  Modelica.Blocks.Sources.RealExpression m_flowHeaVal(y=couHea.m_flowReq)
    annotation (Placement(transformation(extent={{-96,58},{-76,78}})));
  Modelica.Blocks.Sources.RealExpression THeaInlVal(y=couHea.T1_a_nominal)
    annotation (Placement(transformation(extent={{-98,42},{-78,62}})));

  Buildings.Applications.DHC.EnergyTransferStations.CoolingIndirect coo(
    redeclare package Medium = Buildings.Media.Water,
    m1_flow_nominal=0.5,
    m2_flow_nominal=0.5,
    dpValve_nominal=10,
    dp1_nominal=1000,
    dp2_nominal=500,
    use_Q_flow_nominal=true,
    Q_flow_nominal=1000,
    T_a1_nominal=7 + 273.15,
    T_a2_nominal=30 + 273.15)
    annotation (Placement(transformation(extent={{-10,-10},{10,10}},
        rotation=90,
        origin={-84,-46})));
  Modelica.Blocks.Sources.Constant TSetCHWS(k=273.15 + 7)
    "Setpoint temperature for building chilled water supply"
    annotation (Placement(transformation(extent={{-182,-96},{-162,-76}})));
  Modelica.Blocks.Sources.Trapezoid tra(
    amplitude=1.5,
    rising(displayUnit="h") = 10800,
    width(displayUnit="h") = 10800,
    falling(displayUnit="h") = 10800,
    period(displayUnit="h") = 43200,
    offset=273 + 3.5)
    "District supply temperature trapezoid signal"
    annotation (Placement(transformation(extent={{-216,-44},{-196,-24}})));
  Buildings.Fluid.Sources.Boundary_pT souDis(
    p(displayUnit="Pa") = 300000 + 800,
    use_T_in=true,
    nPorts=1,
    redeclare package Medium = Buildings.Media.Water,
    T=278.15)
    "District (primary) source"
    annotation (Placement(transformation(extent={{-184,-48},{-164,-28}})));
  Buildings.Fluid.Sensors.TemperatureTwoPort TDisSup(
    redeclare package Medium = Medium,
    m_flow_nominal=m1_flow_nominal,
    T_start=278.15)
    "District-side (primary) supply temperature sensor"
    annotation (Placement(transformation(extent={{-140,-56},{-120,-36}})));
  Buildings.Fluid.Sensors.TemperatureTwoPort TDisRet(
    redeclare package Medium = Medium,
    m_flow_nominal=m1_flow_nominal,
    T_start=287.15)
    "District-side (primary) return temperature sensor"
    annotation (Placement(transformation(extent={{-118,-8},{-138,12}})));
  Buildings.Fluid.Sources.Boundary_pT sinDis(
    nPorts=1,
    redeclare package Medium = Buildings.Media.Water,
    p=300000,
    T=287.15)
    "District-side (primary) sink"
    annotation (Placement(transformation(extent={{10,-10},{-10,10}},
        rotation=180,
        origin={-170,14})));
  Buildings.Fluid.Movers.FlowControlled_m_flow pumpBuiding(
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState,
    allowFlowReversal=false,
    nominalValuesDefineDefaultPressureCurve=true,
    dp_nominal=6000,
    m_flow_nominal=0.5,
    redeclare package Medium = Buildings.Media.Water)
    "Building-side (secondary) pump" annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=180,
        origin={-46,-108})));
  Buildings.Fluid.Storage.ExpansionVessel exp(redeclare package Medium = Medium,
      V_start=1000)
    "Expansion tank"
    annotation (Placement(transformation(extent={{-10,10},{10,-10}},
        rotation=0,
        origin={-112,-118})));
  Buildings.Fluid.HeatExchangers.HeaterCooler_u2 CoolingUnit(
    m_flow_nominal=0.5,
    dp_nominal=2,
    redeclare package Medium = Buildings.Media.Water,
    Q_flow_nominal=-1000)  "A Simplified Air Terminal of Cooling Unit"
    annotation (Placement(transformation(extent={{42,-98},{72,-70}})));
  Modelica.Blocks.Math.Gain gain(k=1)
    annotation (Placement(transformation(extent={{138,-36},{158,-16}})));
  Modelica.Blocks.Math.Gain gain1(k=-1/(cp*(16 - 7)))
    annotation (Placement(transformation(extent={{122,-138},{102,-118}})));
  Buildings.HeatTransfer.Sources.PrescribedHeatFlow prescribedHeatFlow
    annotation (Placement(transformation(extent={{34,-24},{44,-14}})));
  Modelica.Blocks.Sources.CombiTimeTable QCoo(
    timeScale=3600,
    extrapolation=Modelica.Blocks.Types.Extrapolation.Periodic,
    table=[0,-120; 6,-100; 9,-200; 12,-210; 18,-150; 24,-100; 30,-120; 36,-110;
        42,-200; 48,-120; 54,-150])
    "Cooling demand"
    annotation (Placement(transformation(extent={{-74,-4},{-54,16}})));
equation
  connect(weaDat.weaBus, building.weaBus) annotation (Line(
      points={{72,26},{70,26},{70,-2},{71.13,-2}},
      color={255,204,51},
      thickness=0.5));
  connect(supHea.ports[1], couHea.port_a)
  annotation (Line(points={{-20,58},{-12,58},{-12,56},{30,56}},   color={0,127,255}));
  connect(couHea.port_b, sinHea.ports[1])
  annotation (Line(points={{50,56},{130,56}},                   color={0,127,255}));
  connect(supHea.m_flow_in, m_flowHeaVal.y)
    annotation (Line(points={{-42,66},{-66,66},{-66,68},{-75,68}}, color={0,0,127}));
  connect(THeaInlVal.y, supHea.T_in) annotation (Line(points={{-77,52},{-66,52},
          {-66,62},{-42,62}},                                                                       color={0,0,127}));
  connect(couHea.heaPorLoa, building.heaPorHea) annotation (Line(points={{40,46},
          {40,-5.9},{58,-5.9}},               color={191,0,0}));
  connect(building.Q_flowHeaReq, couHea.Q_flowReq) annotation (Line(points={{85.3,
          -7.2},{100,-7.2},{100,44},{46,44},{46,48},{28,48}},
                                                            color={0,0,127}));
  connect(building.m_flowHeaLoa, couHea.m_flow2) annotation (Line(points={{85.3,
          -11.1},{106,-11.1},{106,72},{16,72},{16,64},{28,64}},
                                                       color={0,0,127}));
  connect(TSetCHWS.y, coo.TSet)
    annotation (Line(points={{-161,-86},{-84,-86},{-84,-58}},
                                                   color={0,0,127}));
  connect(tra.y, souDis.T_in)
    annotation (Line(points={{-195,-34},{-186,-34}},
                                                 color={0,0,127}));
  connect(souDis.ports[1], TDisSup.port_a)
    annotation (Line(points={{-164,-38},{-164,-46},{-140,-46}},
                                                          color={0,127,255}));
  connect(TDisSup.port_b, coo.port_a1) annotation (Line(points={{-120,-46},{-120,
          -56},{-90,-56}},
                      color={0,127,255}));
  connect(coo.port_b1, TDisRet.port_a) annotation (Line(points={{-90,-36},{-90,2},
          {-118,2}},          color={0,127,255}));
  connect(TDisRet.port_b, sinDis.ports[1])
    annotation (Line(points={{-138,2},{-138,14},{-160,14}},
                                                        color={0,127,255}));
  connect(coo.port_b2, pumpBuiding.port_a) annotation (Line(points={{-78,-56},{-68,
          -56},{-68,-108},{-56,-108}}, color={0,127,255}));
  connect(exp.port_a, pumpBuiding.port_a)
    annotation (Line(points={{-112,-108},{-56,-108}}, color={0,127,255}));
  connect(pumpBuiding.port_b, CoolingUnit.port_a) annotation (Line(points={{-36,
          -108},{8,-108},{8,-84},{42,-84}}, color={0,127,255}));
  connect(CoolingUnit.port_b, coo.port_a2) annotation (Line(points={{72,-84},{108,
          -84},{108,-36},{-78,-36}},                   color={0,127,255}));
  connect(building.Q_flowCooAct[1], gain.u)
    annotation (Line(points={{85.3,-26.7},{96,-26.7},{96,-26},{136,-26}},
                                                            color={0,0,127}));
  connect(gain.y, CoolingUnit.u) annotation (Line(points={{159,-26},{170,-26},{170,
          -58},{-10,-58},{-10,-73.92},{39,-73.92}},
                                                color={0,0,127}));
  connect(gain1.y, pumpBuiding.m_flow_in) annotation (Line(points={{101,-128},{-46,
          -128},{-46,-120}}, color={0,0,127}));
  connect(gain1.u, gain.u) annotation (Line(points={{124,-128},{124,-26},{136,-26}},
        color={0,0,127}));
  connect(prescribedHeatFlow.port, building.heaPorCoo[1]) annotation (Line(
        points={{44,-19},{54,-19},{54,-24.1},{58,-24.1}}, color={191,0,0}));
  connect(QCoo.y[1], prescribedHeatFlow.Q_flow) annotation (Line(points={{-53,6},
          {8,6},{8,-19},{32.9,-19}}, color={0,0,127}));
  annotation (
  Documentation(info="<html>
  <p>
  This example illustrates the use of a house model (RC) from (Buildings.Applications.DHC.Loads.BaseClasses.RCBuilding), 
  and a Energy Transfer Station (ETS) model from (Buildings.Applications.DHC.EnergyTransferStations.CoolingIndirect). 
  The house transfers heat from a a simplified air terminal to the ETS, under cooling mode.
  </p>
  </html>"),
  Diagram(
  coordinateSystem(preserveAspectRatio=false, extent={{-220,-140},{140,80}})),
  __Dymola_Commands(file="Resources/Scripts/Dymola/Applications/DHC/Loads/Examples/CouplingRC.mos"
        "Simulate and plot"),
    Icon(coordinateSystem(extent={{-220,-140},{140,80}})));
end CouplingETS_RC_Yanfei;
