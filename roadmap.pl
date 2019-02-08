#!/usr/bin/perl
use strict;
use warnings;

#=============================================================================
# Package Imports
#=============================================================================

use yEd::Document;
use List::MoreUtils qw(first_index);
use Text::Wrap;
use Tree::Simple;
use Tree::Simple::VisitorFactory;
use Date::Format;
#use Tree::Simple::View::ASCII;
#use Data::Dump;

#=============================================================================
# Global Variables
#=============================================================================

my $infile;
my $outfile;
my $title = "";
my $legend = 0;
my $classification = "";
my $date = "";
my @lineColors;
my @events;
my $document;
my @components;
my $line_height = 80;
my $event_width = 160;
my $line_width = 4;
my $wrap_width = 15;
my $current_y = 0;
my $root;
my $max_x = 0;
my $max_y = 0;

#=============================================================================

sub dumpEventIDs
{
  print "eventIDs: [";
  for (my $i = 0; $i < scalar @events; $i++)
  {
    print $events[$i][0] . ", ";
  }
  print "]\n";
}

#=============================================================================

sub placeNodes
{
  my $root = shift;
  my $srcyEdNode = shift;
  
  my @nodes = @{$root->getAllChildren()};
  if (scalar @nodes == 0)
  { 
    $current_y++;
    return;
  }
  foreach my $node (@nodes)
  {
    my $x = $root->getDepth() + 1;
    my @nodeVal = @{$node->getNodeValue()};
    #dd \@nodeVal;
    my $color = $lineColors[$nodeVal[6]];
    my $text = $nodeVal[1];
    my $typeS = $nodeVal[3];
    $x = $x * $event_width;
    if ($x > $max_x) {$max_x = $x; }
    my $y = $current_y * $line_height;
    if ($max_y < $y) {$max_y = $y;}
    my $yEdNode;
    if ($typeS eq 'Deliverable')
    {
      $yEdNode = $document->addTemplateNode ('Deliverable', 'x' => $x, 'y' => $y);
      $yEdNode->setProperties ('fillColor' => 'none', 'borderColor' => $color);
    }
  
    if ($typeS eq 'Function')
    {
      $yEdNode = $document->addTemplateNode ('Function', 'x' => $x, 'y' => $y);
      $yEdNode->setProperties ('fillColor' => $color, 'borderColor' => $color);
    }
    
    if ($typeS eq 'Capability')
    {
      $yEdNode = $document->addTemplateNode ('Capability', 'x' => $x, 'y' => $y);
      $yEdNode->setProperties ('fillColor' => $color, 'borderColor' => $color);
    }
  
    if ($typeS eq 'Decision')
    {
      $yEdNode = $document->addTemplateNode ('Decision', 'x' => $x, 'y' => $y);
    }
    
    if ($typeS eq 'Milestone')
    {
      $yEdNode = $document->addTemplateNode ('Milestone', 'x' => $x, 'y' => $y);
      $yEdNode->setProperties ('fillColor' => $color, 'borderColor' => $color);
    }
    
    if ($yEdNode eq "")
    {
      $yEdNode = $document->addTemplateNode ('Unknown', 'x' => $x, 'y' => $y);
      $yEdNode->setProperties ('fillColor' => $color, 'borderColor' => $color);
    }
    
#    my $yEdNode = $document->addTemplateNode ('Deliverable', 'x' => ($x * $event_width), 'y' => ($current_y * $line_height));
#    $yEdNode->setProperties ('fillColor' => 'none', 'borderColor' => $color);
    my $label = yEd::Label::NodeLabel->new($document->getTemplateLabel('nodelabel'));
    # Word-wrap text if it is too wide
    $Text::Wrap::columns = $wrap_width;
    $text = wrap('', '', $text);
    $label->setProperties('text' => $text, 'positionModell' => 'sides-s');
    $yEdNode->addLabel($label);
    push @nodeVal, $yEdNode->id;
    $node->setNodeValue (\@nodeVal);
    #print $text . "\n";
    #if ($srcyEdNode ne '')
    #{
#      my $edge = $document->addNewEdge('PolyLineEdge', $srcyEdNode, $yEdNode, 'lineWidth' => $line_width, 'smoothBend' => 1, 'lineColor' => $color);
#    }
    placeNodes ($node, $yEdNode);
  }
}

#=============================================================================
sub findTreeyEdId
{
  my $event = shift;
  if ($event == 0) {return -1;}
  my $tf = Tree::Simple::VisitorFactory->new();
  my $visitor = $tf->get("FindByUID");
  $visitor->includeTrunk(1);
  $visitor->searchForUID($event);
  $root->accept($visitor);
  my $result = $visitor->getResult();
  if ($result ne '')
  {
    my @nodeVal = @{$result->getNodeValue()};
    return $nodeVal[7];
  }
  return -1;
}

#=============================================================================
sub shiftTargetNode 
{
  my $node = shift;
  my $yEdNodeId = shift;
  my $x = shift;
  
  $x = $x / $event_width;
  
  $x = $x + 1;
  
  my $yEdNode = $document->getNodeById ($yEdNodeId);
  
  #print "src_x: " . ($x * $event_width) . "\n";
  
  return ($x * $event_width);
}

#=============================================================================
sub placeLinks
{
  my $root = shift;
  my @nodes = @{$root->getAllChildren()};
  if (scalar @nodes == 0)
  { return; }
  foreach my $node (@nodes)
  {
    my @nodeVal = @{$node->getNodeValue()};
    my $nodeID = $nodeVal[0];
    my $predS = $nodeVal[4];
    my $color = $lineColors[$nodeVal[6]];
    my $yEdTgtNodeId = $nodeVal[7];
    #print "Node ID: " . $nodeID . " yEd Node ID: " . $yEdTgtNodeId . " Predecessors: " . $predS . "\n";
    if ($predS ne '')
    {
      my @predA = split ':', $predS;
      foreach my $pred (@predA)
      {
        my $yEdSrcNodeId = findTreeyEdId ($pred);
        if ($yEdSrcNodeId != -1)
        {
          my $yEdSrcNode = $document->getNodeById ($yEdSrcNodeId); 
          my $yEdTgtNode = $document->getNodeById ($yEdTgtNodeId);
          my $edge = $document->addNewEdge('PolyLineEdge', $yEdSrcNode, $yEdTgtNode, 'lineWidth' => $line_width, 'smoothBend' => 1, 'lineColor' => $color);
          
          my $src_y = $yEdSrcNode->y;
          my $tgt_y = $yEdTgtNode->y;
          my $src_x = $yEdSrcNode->x;
          my $tgt_x = $yEdTgtNode->x;
          if ($src_x >= $tgt_x)
          {
            #print $nodeID . " reverse link!" . $nodeVal[1] . "src_x: " . $src_x . " tgt_x: " . $tgt_x . "\n";
            $tgt_x = shiftTargetNode($node, $yEdTgtNodeId, $src_x);
            $yEdTgtNode->setProperties ('x' => $tgt_x);
          }
          
          #@{$root->getAllChildren()}
          
          # Got to look at the *source's* child list to see if it is 0 length!
          #my $srcNode = findTreeNode ($pred);
          
#          my $label = yEd::Label::EdgeLabel->new($nodeVal[1] . " ". scalar @{$srcNode->getAllChildren()});
#          $edge->addLabel($label);
          if 
               ($src_y != $tgt_y)
#             && 
#               (
#                 (abs($src_x - $tgt_x) < $event_width) ))
#               || 
#                (scalar @{$node->getAllChildren()} == 0 )
 #              )
 #            )
          {
            $src_y = $src_y + 12.5;
            $tgt_y = $tgt_y + 12.5;
            $src_x = $tgt_x - ($event_width / 2);
            $tgt_x = $tgt_x - ($event_width / 4);
            $edge->addWaypoint ($src_x, $src_y);
            $edge->addWaypoint ($tgt_x, $tgt_y);
          }
        }
      }
    }
    placeLinks ($node);
  }
}

#=============================================================================

sub allocateChildren
{
  my $root = shift;
  
#  my $tree_view = Tree::Simple::View::ASCII->new ($root);
#  $tree_view->includeTrunk(1);
#  print $tree_view->expandAll();
  #dumpEventIDs;
  
  my @parents = @{$root->getAllChildren()};
  foreach my $parent (@parents)
  {
    my $i = 0;
    while ($i < scalar @events)
    {
      my $predS = $events[$i][4];
      my @predArr = split ':', $predS;
      if ($predArr[0] == @{$parent->getNodeValue}[0])
#      if ($predArr[0] == $parent->getNodeValue)
      {
#        my $node = Tree::Simple->new($events[$i][0]);
        my $node = Tree::Simple->new($events[$i]);
        $node->setUID($events[$i][0]);
        $parent->addChild($node);
        splice @events,$i, 1;
      }
      else
      {
        $i++;
      }
    }
    allocateChildren ($parent);
  }
}

#=============================================================================

sub parse_config_line
{
  my $key;
  my $val;
  chomp;
  if (($_ ne '') && (!/^\#.*/))
  {
  ($key, $val) = split '=';

  if ($key eq "infile") { $infile = $val; }
  if ($key eq "outfile") { $outfile = $val; }
  if ($key eq "title") { $title = $val; }
  if ($key eq "legend") { $legend = $val; }
  if ($key eq "classification") { $classification = $val; }
  if ($key eq "date") { $date = $val; }
  if ($key eq "lineColor") { push (@lineColors, lc $val); }
  }
}

#=============================================================================
# Read config file
#=============================================================================
print "********************************************************************\n";
print "Reading config.txt\n";
open CFH, "<config.txt";

while (<CFH>)
{
parse_config_line ($_);
}
close CFH;

#=============================================================================
# Read data file
#=============================================================================
print "Reading data file: " . $infile . "\n";
open IFH, "<" . $infile;
# Discard the first line - should contain the column titles
<IFH>;

while (<IFH>)
{
 chomp;
 my @arr = split ',', $_, -1;
 push (@events, \@arr);
 my $tc = $arr[2];
 if (!grep(/^$tc$/,@components))
 {
    push (@components, $tc);
 }
}
close IFH;

#dd \@events;

#=============================================================================
# Add Groupings
#=============================================================================
print "Generating grouping info.\n";
foreach my $event (@events)
{
  # Calculate group
  my $c = @{$event}[2];
  my $group = first_index { $_ eq $c } @components;
  push @{$event}, $group;
}

#=============================================================================
# Pre-sort events
#=============================================================================
print "Pre-sorting events by grouping.\n";
my @s_ev = sort { @{$a}[6] cmp ${$b}[6] } @events;
@events = @s_ev;

#=============================================================================
# Create node tree
#=============================================================================
print "Creating node tree\n";
$root = Tree::Simple->new('root', Tree::Simple->ROOT);

# Populate the first level of the tree
my $i = 0;
while ($i <= $#events)
{
  #print $i . "\n";
  my $predS = $events[$i][4];
  if ($predS eq '')
  {
#    print "adding: " . $events[$i][0] . " at root\n";
#    my $node = Tree::Simple->new($events[$i][0]);
    my $node = Tree::Simple->new($events[$i]);
    $node->setUID($events[$i][0]);
    $root->addChild($node);
    splice @events, $i, 1;
  }
  else
  {
    $i++;
  }
}
allocateChildren ($root);

#my $tree_view = Tree::Simple::View::ASCII->new ($root);
#$tree_view->includeTrunk(1);
#print $tree_view->expandAll();

#=============================================================================
# Create the document
#=============================================================================
print "Creating the document.\n";
$document = yEd::Document->new();

# Create node & edge templates
$document->addNewNodeTemplate('Deliverable', 'ShapeNode', borderType => 'line', borderWidth => 3, height => 25, width => 10, shape => 'rectangle');
$document->addNewNodeTemplate('Function', 'ShapeNode', borderType => 'line', borderWidth => 3, height => 25, width => 10, shape => 'triangle');
$document->addNewNodeTemplate('Capability', 'ShapeNode', borderType => 'line', borderWidth => 3, height => 25, width => 10, shape => 'rectangle');
$document->addNewNodeTemplate('Decision', 'ShapeNode', fillColor => '#00000000', borderColor => '#000000', borderType => 'line', borderWidth => 5, height => 25, width => 25, shape => 'ellipse');
$document->addNewNodeTemplate('Milestone', 'ShapeNode', borderType => 'line', borderWidth => 3, height => 25, width => 25, shape => 'diamond');
$document->addNewNodeTemplate('Unknown', 'ShapeNode', borderType => 'line', borderWidth => 3, height => 25, width => 25, shape => 'octagon');
$document->addNewLabelTemplate('nodelabel', 'NodeLabel', '', 'positionModell' => 'sides-s');

#=============================================================================
# Walk the tree and place nodes
#=============================================================================
print "Placing events in document.\n";
placeNodes ($root, '');

#=============================================================================
# Walk the tree and place links
#=============================================================================
print "Placing links in document.\n";
placeLinks ($root);

#=============================================================================
# Walk the tree and place links
#=============================================================================
my $top = -80;

if ($date ne '')
{
  my $node = $document->addNewNode ('ShapeNode', 'x' => ($max_x / 2), 'y' => -80, 'borderColor' => '#00000000', 'fillColor'=>'#00000000');
  my $label = yEd::Label::NodeLabel->new(time2str ($date, time));
  $label->setProperties ('fontSize' => '18', 'fontStyle' => 'bold');
  $node->addLabel($label);
  $top = -140;
}

if ($title ne '')
{
  my $node = $document->addNewNode ('ShapeNode', 'x' => ($max_x / 2), 'y' => $top, 'borderColor' => '#00000000', 'fillColor'=>'#00000000');
  my $label = yEd::Label::NodeLabel->new($title);
  $label->setProperties ('fontSize' => '48', 'fontStyle' => 'bold');
  $node->addLabel($label);
}

if ($legend)
{
  $max_y = $max_y + $line_height;
  my $x = 0;
  for (my $i = 0; $i < scalar @components; $i++)
  {
    my $node = $document->addNewNode ('ShapeNode', 'width' => '30', 'height' => $line_width, 'x' => $x, 'y'=> $max_y);
    $node->setProperties ('fillColor' => $lineColors[$i], 'borderColor' => $lineColors[$i], shape => 'rectangle');

    my $label = yEd::Label::NodeLabel->new($document->getTemplateLabel('nodelabel'));
    $label->setProperties('text' => $components[$i], 'positionModell' => 'sides-s');
    $node->addLabel($label);    
    $x = $x + $event_width;
  }
  $max_y = $max_y + 40;
}

if ($classification ne '')
{
  my $node = $document->addNewNode ('ShapeNode', 'x' => ($max_x / 2), 'y' => $max_y, 'borderColor' => '#00000000', 'fillColor'=>'#00000000');
  my $label = yEd::Label::NodeLabel->new($classification);
  $label->setProperties ('fontSize' => '18', 'fontStyle' => 'bold');
  $node->addLabel($label);
}

#=============================================================================
# Finalise the document
#=============================================================================
# Create final document
my $xmlstring = $document->buildDocument();

print "Writing " . $outfile . "\n";
open OFH, ">" . $outfile;
print OFH $xmlstring;
close OFH;
print "Finished.\n";
