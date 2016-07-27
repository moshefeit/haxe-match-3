package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import openfl.display.Graphics;
import flixel.group.FlxGroup;

import World.*;
import Hex.*;
import Math.*;

using flixel.util.FlxSpriteUtil;

/**
 * ...
 * @author Moshe Feit
 */
class Block extends FlxSprite
{
	// Props
	public var settled:Dynamic;
	public var fallingLane:Dynamic;
	public var checked:Dynamic;
	public var targetAngle:Dynamic;
	public var color:Dynamic;
	public var widthWide:Dynamic;
	public var fillStyle:Dynamic;
	
	// Trig.
	public var deleted:Dynamic;
	public var removed:Dynamic;
	public var tint:Dynamic;
	public var opacity:Dynamic;
	public var initializing:Dynamic;
	
	// ID
	public var ict:Dynamic;
	public var iter:Dynamic;
	public var initLen:Dynamic;
	public var attachedLane:Dynamic;
	public var distFromHex:Dynamic;
	public var height:Dynamic;
	public var difficulty:Dynamic;
	
	public var p1, p2, p3, p4;

	public function new(fallingLane, color, iter, distFromHex, settled, difficulty) 
	{
		super();
		
		// Is property
		this.settled = (settled == null) ? 0:1;
		this.height = settings.blockHeight;
		this.fallingLane = fallingLane;
		this.checked = 0;
		this.angle = 90 - (30 + 60 * fallingLane);
		this.angularVelocity = 0;
		this.targetAngle = this.angle;
		this.color = color;
		
		// Is trigger
		this.deleted = 0;
		this.removed = 0;
		this.tint = 0;
		this.opacity = 1;
		this.initializing = 1;
		
		// Is identity
		this.ict = MainHex.ct;
		this.iter = iter;
		this.initLen = settings.creationDt;
		this.attachedLane = 0;
		this.difficulty = difficulty;
		this.distFromHex = settings.distFromHex;
		
		getIndex();
		draw();
	}
	
	override public function update(elapsed:Float):Void
	{
		incrementOpacity();
	}
	
	public function incrementOpacity()
	{
		if (this.deleted)
		{
			if (this.opacity >= 0.925)
			{
				var tLane = this.attachedLane - MainHex.position;
				tLane = MainHex.sides - tLane;
				
				while (tLane < 0)
				{
					tLane += MainHex.sides;
				}
				
				tLane %= MainHex.sides;
				MainHex.shakes.push(
					{lane:tLane, magnitude:3 * (flixel.system.devicePixelRatio ? flixel.systemwindow.devicePixelRatio : 1) *
					(settings.scale)};
				)
			}
			
			this.opacity = this.opacity - 0.075 * MainHex.dt;
			if (this.opacity <= 0)
			{
				this.opacity = 0;
				this.deleted = 2;
			}			
		}
	}
	
	public function getIndex()
	{
		var parentArr = MainHex.blocks[this.attachedLane];
		
		for (for i in 0...parrentArr.length)
		{
			if ( parentArr[i] == this)
			{
				return i;
			}
		}
	}
	
	override public function draw(attached, index)
	{
		this.height = settings.blockHeight; // Enum
		
		if (Math.abs(flixel.system.scale - flixel.system.prevScale) > 0.000000001)
		{
			this.distFromHex *= (flixel.system.scale / flixel.system.prevScale);			
		}
		
		this.incrementOpacity();
		
		if (attached == null) attached = false; // In case is colliding with a block already
		
		if (this.angle > this.targetAngle) this.angularVelocity -= angularVelocityConst * MainHex.dt;
		else if (this.angle < this.targetAngle) this.angularVelocity += angularVelocity;
		
		if (Math.abs(this.angle - this.targetAngle + this.angularVelocity) <= Math.abs(this.angularVelocity))
		{
			this.angle = this.targetAngle;
			this.angularVelocity = 0;
		} else {
			this.angle += this.angularVelocity;
		}
		
		this.width = 2 * this.distFromHex / Math.sqrt(3);
		this.widthWide = 2 * (this.distFromHex + this.height) / Math.sqrt(3);
		
		if (this.initializing)
		{
			var rat = ((MainHex.ct - this.ict) / this.initLen;
			
			if ( rat > 1) 
			{
				rat = 1;
			}
			
			p1 = new FlxPoint.rotate(((-this.width / 2) * rat, this.height / 2), this.angle);
			p2 = new FlxPoint.rotate(((this.width / 2) * rat, this.height / 2), this.angle);
			p3 = new FlxPoint.rotate(((this.widthWide / 2) * rat, -this.height / 2), this.angle);
			p4 = new FlxPoint.rotate((( -this.widthWide / 2) * rat, -this.height / 2), this.angle);
			
			if ((MainHex.ct - this.ict) >= this.initLen) {
				this.initializing = 0;
			}
			
		} else {
			p1 = new FlxPoint.rotate((-this.width / 2, this.height / 2), this.angle);
			p2 = new FlxPoint.rotate((this.width / 2, this.height / 2), this.angle);
			p3 = new FlxPoint.rotate((this.widthWide / 2, -this.height / 2), this.angle);
			p4 = new FlxPoint.rotate((-this.widthWide / 2, -this.height / 2), this.angle);
		}
		
		if (this.deleted)
		{
			this.fillStyle = { color: new FlxColor.toWebString(this.color) };
		}
		
		Graphics.TILE_ALPHA = this.opacity; // FlxSpriteUtil alternative
		
		var baseX = FlxSprite.getGraphicMidpoint().x;
		var baseY = FlxSprite.getGraphicMidpoint().y;
			
		FlxSpriteUtil.drawPolygon(this, [p1, p2, p3, p4], this.color);
		
		this.tint -= 0.02 * MainHex.dt;
		
		if (this.tint < 0)
		{
			this.tint = 0;
		}
	}
	
	Graphics.TILE_ALPHA = 1;	
}