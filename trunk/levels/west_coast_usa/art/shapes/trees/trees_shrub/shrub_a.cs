
singleton TSShapeConstructor(Shrub_aDae)
{
   baseShape = "./shrub_a.dae";
};

function Shrub_aDae::onLoad(%this)
{
   %this.addImposter("0", "6", "0", "0", "256", "0", "0");
}
