
function prestagelightDae::onLoad(%this)
{
   %this.addSequence("ambient", "prestage_start", "0", "5", "1", "0");
   %this.setSequenceCyclic("prestage_start", "0");
   %this.addSequence("ambient", "prestage_end", "9", "15", "1", "0");
   %this.setSequenceCyclic("prestage_end", "0");
   %this.setSequenceCyclic("ambient", "0");
}

singleton TSShapeConstructor(prestagelightDae)
{
   baseShape = "./prestagelight.dae";
};
