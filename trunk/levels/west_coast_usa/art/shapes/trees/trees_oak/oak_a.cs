
singleton TSShapeConstructor(Oak_aDae)
{
   baseShape = "./oak_a.dae";
};

function Oak_aDae::onLoad(%this)
{
   %this.setBounds("-7.077178 -4.55655193 -0.897789478 5.0261569 3.8572681 9.2440834");
   %this.setNodeTransform("bb__autobillboard25", "0 0 0 0 0 -1 0.211673006", "1");
   %this.addImposter("0", "6", "0", "0", "128", "0", "0");
   %this.setNodeParent("bb__autobillboard25", "start00");
}
