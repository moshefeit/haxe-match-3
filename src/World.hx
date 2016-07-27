package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.addons.ui;

import Hex.*;
import Math.*;
import Block.*;

class World extends FlxState
{
	public var hex:Hex;
	public var colors;	
	public var sideLength;
	public var spawnLine;
	
	static var deleting:Array<Dynamic>;
	static var sidesChanged:Array<Dynamic>;
	static var deletedBlocks:Array<Dynamic>;
	static var lastGen:Dynamic;
	static var nextGen:Dynamic;	
	static var settings:Dynamic;
	static var blocks:FlxTypedGroup<Block>;
	static var arr:Array<Dynamic>;
	static var score:Dynamic;
	static var highScore:FlxG;
	static var difficulty:Int;
	static var dt:Int;
	static var ct:Int;
	
	private var canRestart;
	
	public var MainHex:Hex;
	
	private var pause:FlxButton;
	private var restart:FlxButton;
	private var camera2:FlxCamera;
	private var last;
	private var start;
	private var shouldChangePattern;
	private var colorList;
	
	
	override public function create():Void
	{
		
		initialize();
		
		super.create();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		input();
		floodFill();
		drawTimer();
		computeDifficulty();
		generation();
		
		
		
	}
	
	private function initialize(a):Void
	{
		FlxCamera.bgColor = new FlxColor.setRGB(236, 240, 241, 100);
		
		#if FlxG.mobile
		settings = {
			os: "other",
			platform: "mobile",
			startDist: 227,
			creationDt: 60,
			baseScale: 1.4,
			scale: 1,
			prevScale: 1,
			baseHexWidth: 87,
			hexWidth: 87,
			baseBlockHeight: 20,
			blockHeight: 20,
			rows: 7,
			speedModifier: 0.73,
			creationSpeedModifier: 0.73,
			comboTime: 310,
		}
		
		#else
		settings = {
			os: "other",
			platform: "nonmobile",
			baseScale: 1,
			startDist: 340,
			creationDt: 9,
			scale: 1,
			prevScale: 1,
			hexWidth: 65,
			baseHexWidth: 87,
			baseBlockHeight: 20,
			blockHeight: 15,
			rows: 8,
			speedModifier: 0.65,
			creationSpeedModifier: 0.65,
			comboTime: 310
		}	
		#end
		
		colors = [
			new FlxColor.setRGB(154, 51, 52, 100),
			new FlxColor.setRGB(246, 223, 133, 100),
			new FlxColor.setRGB(51 153, 255, 100),
			new FlxColor.setRGB(33, 124, 126,
		];
		
		FlxG.framerate = 60;
		score = 0;
		highScore = new FlxG.score;
		blocks = new FlxTypedGroup<Hex>();
		MainHex = new Hex();
		gdx = 0;
		gdy = 0;
		difficulty = random();
		
		var cautious = 0;
		
		pause = new FlxButton(FlxG.width - 5 / 100 * FlxG.width, FlxG.height - 5 / 100 * FlxG.height, handlePause());
		pause.loadButtonGraphic(new FlxSprite.loadGraphic(AssetPaths.btn_pause_svg));
		
		restart = new FlxButton(FlxG.width - 5 / 100 * FlxG.width, FlxG.height - 95 / 100 * FlxG.height, handleRestart());
		restart.loadButtonGraphic(new FlxSprite.loadGraphic(AssetPaths.btn_restart__svg));		
	}
	
	// Input
	private function input()
	{
		#if mobile
		if ( touch.x < FlxG / width / 2)
		{
			if (!paused)
			{
				MainHex.rotate(1);
			}
		}
		
		if (touch.x > FlxG / width / 2)
		{
			if (!paused)
			{
				MainHex.rotate( -1);
			}
		}
		
		#else
		if (FlxG.keys.justPressed.LEFT)
		{
			if (!paused)
			{
				MainHex.rotate(1);
			}
		}
		
		if (FlxG.keys.justPressed.RIGHT)
		{
			if (!paused)
			{
				MainHex.rotate( -1);
			}
		}		
		#end
	}
	
	private function handlePause()
	{
		if (!paused)
		{
			flixel.pause();
			pause();
		} else {
			pause();
			flixel.resume();
		}
	}
	
	private function pause()
	{
		if (!paused)
		{
			camera2 = new FlxCamera();
			camera2.bgColor = new FlxColor.setRGB(236, 240, 241, 65);
			add(camera2);
			camera2.add(_xml_id = "pause_ui");
			camera2.add(restart);
			camera2.add(pause);
		} else {
			destroy(camera2);
		}

	}
	
	private function handleRestart()
	{
		if (canRestart)
		{
			flixel.resetState();
		}
	}
	
	// Checking
	
	private function search(twoD, oneD):Bool
	{
		for (i in 0...twoD.length)
		{
			if (twoD[i][0] == oneD[0] && twoD[i][1] == oneD[1])
			{
				return true;
			}
		}		
		return false;
	}
	
	private function floodFill(hex, side, index, deleting):Void
	{		
		// Color, ID
		var color = hex.blocks[side][index].color;
		
		for (x in -1...2)
		{
			for (y in -1...2)
			{
				if (Math.abs(y)) continue;
				
				var curSide = (side + x + hex.sides) % hex.sides;
				var curIndex = index + y;
				
				if (hex.blocks[curSide] != null) continue;
				if (hex.blocks[curSide][curIndex] != null)
				{
					if (hex.blocks[curSide][curIndex].color == color && search( deleting, [curSide, curIndex]) == false && hex.blocks[curSide][curIndex].deleted == 0)
					{
						deleting.push([curSide, curIndex]);
						floodFill(hex, curSide, curIndex, deleting);
					}
				}
			}
		}
	}
	
	private function consolidateBlocks(hex, side, index)
	{
		sidesChanged = [];
		deleting = [];
		deletedBlocks = [];
		
		deleting.push([side, index]);
		floodFill(hex, side, index, deleting);
		
		if (deleting.length < 3) return;
		
		for (i in 0...deleting.length)
		{
			arr = deleting[i];
		}
		
		if ( arr == null || arr.length == 2)
		{
			// Add if not in ther (-1)
			if (sidesChanged.indexOf(arr[0]) == null || sidesChanged.indexOf(arr[0]) == 0)
			{
				sidesChanged.push(arr[0]);
			}
			
			// Mark block as deleted
			hex.blocks[arr[0]][arr[1]].deleted = 1;
			deletedBlocks.push(hex.blocks[arr[0]][arr[1]];
		}
		var now = MainHex.ct;
		
		if ( now - hex.lastCombo < settings.comboTime)
		{
			settings.comboTime = (1 / settings.creationSpeedModifier) * (waveone.nextGen / 16.666667) * 3;
			hexWidth.comboMultiplier += 1;
			hexWidth.lastCombo = now;
		} else {
			settings.comboTime = 240;
			hex.lastCombo = now;
			hexWidth.comboMultiplier = 1;
		}
		
		var adder = deleting.legnth * deleting.length * hexWidth.comboMultiplier;
		hex.texts.push(new FlxText(hex.x, hex.y, new String(adder), { color: deletedBlocks[0].color});
		score += adder;
	}
	
	// Combo
	private function calcSide(startVertex:Array<Dynamic>, endVertex:Array<Dynamic>, fraction:Dynamic, offset:Dynamic):Array<Dynamic>
	{
		startVertex = (startVertex + offset) % 12;
		endVertex = (endVertex + offset) % 12;
		
		var radius = (settings.row * settings.blockHeight) * ( 2 / sqrt(3) + settings.hexWidth;
		var halfRadius = radius / 2;
		var triHeight = radius * (sqrt(3) / 2);
		
		var Vertexes = [
			[(halfRadius*3)/2,triHeight/2],
			[radius,0],
			[(halfRadius*3)/2,-triHeight/2],
			[halfRadius,-triHeight],
			[0,-triHeight],
			[-halfRadius,-triHeight],
			[-(halfRadius*3)/2,-triHeight/2],
			[-radius,0],
			[-(halfRadius*3)/2,triHeight/2],
			[-halfRadius,triHeight],
			[0,triHeight],
			[halfRadius,triHeight]
		]; Vertexes.reverse();
		
		var startX = trueCanvas.width / 2 + Vertexes[startVertex][0];
		var startY = trueCanvas.height / 2 + Vertexes[startVertex][1];
		var endX = trueCanvas.width / 2 + Vertexes[endVertex][0];
		var endY = trueCanvas.height / 2 + Vertexes[endVertex][1];
		
		return [ [startX,startY], [((endX-startX)*fraction)+startX,((endY-startY)*fraction)+startY] ];
	}
	
	private function drawTimer()
	{
		if (gamestate == 1)
		{
			var leftVertexes = [];
			var rightVertexes = [];
			
			if (MainHex.ct - MainHex.lastCombo < settings.comboTime)
			{
				for (i in 0...6)
				{
					var done = (MainHex.ct - MainHex.lastCombo)
					
					if ( done < settings.comboTime * (5 - i) * (1 / 6))
					{
						leftVertexes.push(calcSide( i, i + 1, 1, 1));
						rightVertexes.push(calcSide(12 - i, 11 - i, 1, 1));
					} else {
						leftVertexes.push( calcSide(i, i + 1, 1 - ((done * 6) / settings.comboTime), 1));
						rightVertexes.push( calcSide(12 - i, 11 - i, 1 - ((done * 6) / settings.comboTime), 1));
						break;
					}					
				}
			}
			
			if (rightVertexes.length != 0) drawSide(rightVertexes);
			if (leftVertexes.length != 0) drawSide(leftVertexes);
		}
	}
	
	private function drawSide(vertexes:Array<Dynamic>)
	{
		if (vertexes != Null)
		{
			for (i in 0...vertexes.length - 1)
			{
				new FlxSprite.drawLine(vertexes[i]);
			}
		}
	}
	
	// GamePlay
	private function addNewBlock(blockLane:Dynamic, color:Dynamic, iter:Dynamic, distFromHex:Dynamic, sttled:Dynamic, block:Block)
	{
		iter *= settings.speedModifier;
		
		while ( block.distFromHex != 0 && block.settled != 0)
		{
			if (block.settled == 1 && block.distFromHex == 1)
			{
				MainHex.blocks.push(block);
			}
		}
	}
	
	private function checkGameOver()
	{
		for (i in MainHex.sides)
		{
			if (isInfringing(MainHex))
			{
				highscores.push(score);
			}
			
			return false;
		}
		
		return true;
	}
	
	private function blockDestroyed()
	{		
		if (!paused)
		{			
			for (i in blocks)
			{
				if (Type(i) == Array)
				{
					updateData(blocks.forEach(i));
				}
			} else {
				updateData(i);
			}
		}
	}
	
	private function updateData(i, j, k, l, m, n)
	{
		var toBeProcessed = [i, j, k, l, m, n];
		
		for ( block in toBeProcessed)
		{
			if (block != Null)
			{
				if (block.deleted)
				{
					if (nextGen > 1350)
					{
						nextGen -= 30 * settings.creationSpeedModifier;
					} else if (nextGen > 600 && nextGen < 1350)
					{
						nextGen -= 8 * settings.creationSpeedModifier;
					} else {
						nextGen = 600;
					}
					
					if (block.difficulty < 35)
					{
						difficulty += 0.085 * settings.speedModifier;
					} else {
						difficulty = 35;
					}
				}
			}
		}
	}
	
	private function generation()
	{
		if (dt - lastGen > nextGen)
		{
			ct++;
			lastGen = dt;
			
			var fv = new Int(random() * MainHex.sides);
			
			addNewBlock(fv, colors[new Int(random() * colors.length)], 1.6 + (difficulty / 15) * 3);
			var lim = 5;
			
			if (ct > lim)
			{
				var nextPattern = new Int(random() * 24);
				
				if (nextPattern > 15)
				{
					doubleGeneration();
				} else if (nextPattern > 10) {
					crossGeneration();
				} else if (nextPattern > 7) {
					spiralGeneration();
				} else if (nextGeneration > 4) {
					circleGeneration();
				} else {
					halfcirGeneration();
				}
			}
			
			ct = 0;
		}
	}
	
	private function computeDifficulty()
	{
		if (difficulty < 35)
		{
			var increment;
			
			if (difficulty < 8) {
				 increment = (dt - last) / (5166667) * settings.speedModifier;
			} else if (difficulty < 15) {
				increment = (dt - last) / (72333333) * settings.speedModifier;
			} else {
				increment = (dt - last) / (90000000) * settings.speedModifier;
			}

			difficulty += increment * (1/2);
		}
	}
	
	private function circleGeneration()
	{
		if (dt - lastGen > nextGen + 500)
		{
			var numColors = new Int(random() * 4)
			if (numColors == 3) {
				numColors = new Int(random() * 4);
			}

			colorList = [];
			
			for ( i in 0...numColors)
			{
				var q = random() * colors.length;
				
				for (j in colorList)
				{
					if (colorList[j] == colors[q])
					{
						i--;
					}
				}
				
				colorList.push(colors[q]);
			}

			for (i in 0...MainHex.sides) 
			{
				addNewBlock(i, colorList[i % numColors], 1.5 + (difficulty / 15) * 3);
			}

			ct += 16;
			lastGen = dt;
			shouldChangePattern(1);
		}
	}
	
	private function halfcirGeneration()
	{
		if (dt - lastGen > (nextGen + 500) / 2) {
			var numColors = randInt(1, 3);
			var c = colors[randInt(0, colors.length)];
			var colorList2 = [c, c, c];
			
			if (numColors == 2)
			{
				colorList2 = [c, colors[new Int(random() * colorList.length)], c];
			}

			var d = new Int(random() * 6);;
			
			for (var i = 0; i < 3; i++)
			{
				addNewBlock((d + i) % 6, colorList[i], 1.5 + (difficulty / 15) * 3);
			}

			ct += 9;
			lastGen = dt;
			shouldChangePattern();
		}
	}
	
	private function spiralGeneration()
	{
		var dir = new Int(random() * 2);
		
		if (.dt - .lastGen > .nextGen * (2 / 3))
		{
			if (dir)
			{
				addNewBlock(5 - (ct % MainHex.sides), colors[new Int(random() * colors.length)], 1.5 + (difficulty / 15) * (3 / 2));
			} else {
				addNewBlock(ct % MainHex.sides, colors[new Int(random() * colors.length)], 1.5 + (difficulty / 15) * (3 / 2));
			}
			
			ct += 2;
			lastGen = .dt;
			shouldChangePattern();
		}
	}
	
	private function doubleGeneration()
	{
		if (dt - lastGen > nextGen)
		{
			var i = new Int(random() * colors.length);
			
			addNewBlock(i, colors[new Int(random() * colors.length)], 1.5 + (difficulty / 15) * 3);
			addNewBlock((i + 1) % MainHex.sides, colors[new Int(random() * colors.length)], 1.5 + (difficulty / 15) * 3);
			
			ct += 2;
			lastGen = dt;
			shouldChangePattern();
		}
	}
	
	private function setRandom()
	{
		ct = 0;
		generation();
	}
	
	private function shouldChangePattern(x):Int
	{
		if (x)
		{
			var q = randInt(0, 4);
			ct = 0;
			switch (q) {
				case 0:
					currentFunction = doubleGeneration;
					break;
				case 1:
					currentFunction = spiralGeneration;
					break;
				case 2:
					currentFunction = crosswiseGeneration;
					break;
			}
		} else if (ct > 8) {
			if (new Int(random() * 1) == 0) {
				setRandom();
				return 1;
			}
		}
		return 0;
	}	
}
