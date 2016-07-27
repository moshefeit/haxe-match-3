package;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.addons.nape.Config;
import flixel.group.FlxGroup;
import nape.phys;

import World.*;
import Math.*;
import Block.*;

/**
 * ...
 * @author Moshe Feit
 */
class Hex extends FlxSprite
{
	public var angularVelocity:Dynamic;
	public var position:Dynamic;
	public var dy:Dynamic;
	public var dt:Int;
	public var sides:Dynamic;
	public var blocks:FlxTypedGroup<Block>;
	public var angle:Dynamic;
	public var targetAngle:Dynamic;
	public var shakes:Array<Dynamic>;
	public var sideLength:Dynamic;
	
	public var x:Dynamic;
	public var y:Dynamic;
	public var ct:Dynamic;
	public var lastCombo:Dynamic;
	public var lastColor:Dynamic;
	public var comboTime:Dynamic;
	public var texts:Array<Dynamic>;
	public var lastRotate:Dynamic;
	public var gdx:Dynamic;
	public var gdy:Dynamic;
	
	public var fillColor:Dynamic;
	public var tempColor:Dynamic;
	public var magnitude:Dynamic;

	public function new():Void
	{
		fillColor = new FlxColor.setRGB(44, 62, 80, 100);
		tempColor = fillColor;
		angularVelocity = 0;
		position = 0;
		dy = 0;
		dt = 1;
		sides = 6;
		blocks = [];
		angle = 180 / sides;
		targetAngle = angle;
		shakes = [];
		this.sideLength = sideLength;
		x = FlxG.width / 2;
		y = FlxG.height / 2;
		ct = 0;
		lastCombo = ct - settings.comboTime;
		lastColorScored = null;
		this.comboTime = 1;
		texts = [];
		gdx = gdy = 0;
		
		for (i in 0...sides)
		{
			blocks.push([]);
		}
		
	}
	
	override public function update(update:Float):Void
	{
		FlxG.overlap(this, blocks, doesBlockCollide);
		addBlock();
	}
	
	private function shake(obj)
	{
		var angle2 = angle;
		angle2 = PI / 180;
		
		var dx = cos(angle2) * crushFactor(obj);
		var dy = sin(angle2) * crushFactor(obj);
		
		gdx -= this.dx;
		gdy += this.dy;
		
		magnitude = crushFactor(obj) / 2 * this.dt;
		
		if (magnitude < 1)
		{
			for (i in 0...shakes.length)
			{
				if (this.shakes[i] == obj)
				{
					shakes.splice(i, 1);
				}
			}
		}
	}
	
	public function addBlock(block:Block)
	{
		if (paused) return;
		block.settled = 1;
		block.tint = 0.6;
		
		var lane = sides - block.fallingLane;
		this.shakes.push({lane:block.fallingLane, magnitude:4.5 * settings.scale)};
		lane += this.position;
		lane = (lane + this.sides) % this.sides;
		block.distFromHex = MainHex.sideLength / 2 * sqrt(3) + block.height * this.blocks[lane].length;
		this.blocks[lane].push(block);
		
		block.attachedLane = lane;
		block.checked = 1;
	}
	
	public function doesBlockCollide(block:Block, position, tArr:Array<Block>)
	{
		if (block.settled) return;
		
		if (block.position == null)
		{
			var arr = new Array<Block>();
			
			if (position <= 0)
			{
				if (block.distFromHex - block.iter * this.dt * settings.scale - (this.sideLength / 2) * sqrt(3) <= 0)
				{
					block.distFromHex = (this.sideLength / 2) * sqrt(3);
					block.settled = 1;
					block.checked = 1;
				} else {
					block.settled = 0;
					block.iter = 1.5 + block.difficulty / 15
					block.iter = block.iter * 3;
				}
			} else {
				if (arr[position - 1].settled && block.distFromHex - block.iter * this.dt * settings.scale - arr[position - 1].distFromHex + arr[position -1].height <= 0)
				{
					block.distFromHex = arr[position - 1].distFromHex + arr[position - 1].height;
					block.settled = 1;
					block.checked = 1;
				} else {
					block.settled = 0;
					block.iter = block.difficulty / 15;
					block.iter = block.iter * 3;
				}
			}
		} else {
			var lane = this.sides - block.fallingLane // - this.position;
			lane += this.position;
			lane = (lane + this.sides) % this.sides;
			
			var arr = new Array<Block>();
			arr = this.blocks[lane];
			
			if (arr.length > 0)
			{
				if ( block.distFromHex + block.iter * dt * settings.scale - arr[arr.length - 1].distFromHex - arr[arr.length - 1].height <= 0)
				{
					block.distFromHex = arr[arr.length - 1].distFrom + arr[arr.length - 1].height;
					this.addBlock(block);
				}
			} else {
				if (block.distFromHex + block, Iterable * dt * settings.scale - (this.sideLength / 2) * sqrt(3) <= 0)
				{
					block.distFromHex = (this.sideLength / 2) * sqrt(3);
					this.addBlock(block);
				}
			}
		}
	}
	
	public function rotate(steps)
	{
		if (FlxG.paused) return;
		
		while (this.position < 0)
		{
			this.position  += 6;
		}
		
		this.position = this.position % this.sides;
		
		blocks.forEach(changeTarget(block, steps));		
		targetAngle = targetAngle - steps * 60;
	}
	
	private function changeTarget(block:Hex, steps:Dynamic)
	{
		block.targetAngle = block.targetAngle - steps * 60;
	}
	
	private function draw()
	{
		this.x = FlxG.width / 2;
		this.y = FlxG.height / 2;
		this.sideLength = settings.hexWidth;
		
		gdx = 0;
		gdy = 0;
		
		var vertices = new Array<FlxPoint>();
		var init = new FlxPoint(this.x - this.sideLength / 2, this.y - settings.hexHeight / 2);
		
		for (i in 0...sideLength - 1)
		{
			var x1 = (init.x - this.x) * cos(this.angle) - (init.y - this.y) * sin(this.angle);
			x1 = x1 + this.x;
			
			var y1 = (init.x - this.x) sin(this.angle) + (init.y - this.y) * cos(this.angle);
			y1 = y1 + this.y;
			
			var point = new FlxPoint(x1, y1);
			vertices.push(point);
		}
		
		new FlxSprite.drawPolygon(vertices, this.fillColor);
	}
	
}