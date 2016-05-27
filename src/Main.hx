package;

import haxe.ds.Vector;
import neko.Lib;
import haxe.io.Input;

/**
 * ...
 * @author Moshe Feit
 */

class Main 
{	

	public static var aList = new Array();
	public static var memberList = new Array();
	static var done:Int;
	static var selection:Int;
	static var idn:Int;
	public static var score:Float;
	public static var move: Int;
	
	static function main() 
	{
		move = 10;	
		var done = 0;
		var selection = 0;
		score = 0;
		
		for (i in 0...5)
		{
			var array = new Array();
			aList.insert(i, array);
		}
		
		while (move != 0)
		{
			done = 0;
			selection = 0;
			
			Sys.println("Select a menu:");
			Sys.println("1. Play");
			Sys.println("2. Exit");
			Sys.println("Remaining moves: " + move );
			
			while (selection < 1 || selection > 2)
			{
				Sys.print("Selection: ");
				selection = Std.parseInt(Sys.stdin().readLine());
				Sys.print("\n");
			}
			
			if (selection == 1 && move != 0)
			{
				move -= 1;
				
				Sys.println("####################");
				createNew();
				viewContainer();
				Sys.println("####################");
				doCleanUp();
				viewContainer();
				Sys.println("Score: " + score);
				Sys.println("####################\n");
			} else if (move == 0)
			{
				Sys.println("You have no more lives!");
			}
			
			if (selection == 2)
			{
				done = 1;
			}
			
			checkRelation();
		}
	}
	
	static function checkRelation()
	{
		for (i in 0...5)
		{
			for (j in 0...5)
			{
				if (aList[i][j] != null)
				{
					aList[i][j].checkRelations(i, j);
				}
			}
		}
	}
	
	static function createNew()
	{
		var done = 0;
		var listpos:Int = Std.random(5);
		var id:Int = Std.random(100);
		
		var y:Int = memberList.length;
		var totalMember:Int = 0;
		
		for ( i in aList )
		{
			totalMember += i.length;
		}
		
		if (totalMember == 25)
		{
			Sys.println("Denied.\nContainer already full\n");
		} else {
			// Determining position and checking
			while (done == 0)
			{
				var pos:Int = Std.random(5);
				done = 1;
				
				if (aList[pos].length == 5)
				{
					done = 0;
				}
				
				listpos = pos;
			}
			
			done = 0;
			
			// Determining ID wether if exist or not
			while ( done == 0 )
			{
				var idn:Int = Std.random(100);
				done = 1;
				
				if (y != 0)
				{
					for (i in memberList)
					{
						if ( i.id == idn )
						{
							done = 0;
						}
					}
				}
				
				id = idn;
			}
			
			var x:Int = aList[listpos].length;
			
			var member = new Member(id, Std.random(3));		
			aList[listpos].insert(x, member);
			memberList.insert(y, member);
			
		}
	}
	
	static function viewContainer()
	{
		for (i in 0...5)
		{
			for (j in 0...5)
			{
				Sys.print("| ");
				
				if (aList[j][i] != null)
				{
					Sys.print(aList[j][i].key);
				} else {
					Sys.print(" ");
				}
				
				Sys.print(" | ");
			}
			
			Sys.print("\n");
		}
		
		Sys.print("\n");
	}
	
	static function doCleanUp()
	{
		var stack = new Array();
		
		for (column in Main.aList)
		{
			for (member in column)
			{
				stack.insert(stack.length, member);
			}
		}
		
		// Tier 1
		for (member in stack)
		{			
			var deleteStack = new Array();
			var nextMove = new Array();
			
			var possible = new Array();			
			
			deleteStack.insert(deleteStack.length, member);
			
			checkRelation(); // Stored is ID
						
			if (member.left != null)
			{
				possible.insert(possible.length, member.left);
			}
			
			if (member.right != null)
			{
				possible.insert(possible.length, member.right);
			}
			
			if (member.upper != null)
			{
				possible.insert(possible.length, member.upper);
			}
			
			if (member.bottom != null)
			{
				possible.insert(possible.length, member.bottom);
			}
			
			for ( moveId in possible )
			{
				for ( i in Main.aList )
				{
					for ( j in i )
					{
						if (j.id == moveId)
						{
							nextMove.insert(nextMove.length, j); // Tier 2 selection
						}
						
					}
				}
			}
			
			possible.slice(0, possible.length);
			
			// Tier 2
			for ( move in nextMove)
			{
				if (Lambda.has(deleteStack, move) == false)
				{
					deleteStack.insert(deleteStack.length, move);
					
					if (move.left != null)
					{
						possible.insert( possible.length, move.left);
					}
					
					if (move.right != null)
					{
						possible.insert( possible.length, move.right);
					}
					
					if (move.upper != null)
					{
						possible.insert( possible.length, move.upper);
					}
					
					if (move.bottom != null)
					{
						possible.insert( possible.length, move.bottom);
					}
					
					for (i in stack)
					{
						for (next in possible)
						{
							if (i.id == next && Lambda.has(nextMove, i) == false)
							{
								nextMove.insert(nextMove.length, i);
							}
						}
					}
					
					nextMove.remove(move);
				}				
			}
			
			if (deleteStack.length >= 3)
			{
				var x:Float = 0.0;
				var y;
				
				if (deleteStack.length == 3)
				{
					x = 1;
				} else if (deleteStack.length > 3 && deleteStack.length <= 5)
				{
					x = 1.5;
				} else if (deleteStack.length > 5)
				{
					x = 2;
				}
				
				move = cast((deleteStack.length * 10 * x / 10 + move), Int);
				
				score = (deleteStack.length * 10 * x) + score;				
				
				for (i in deleteStack)
				{
					// Remove from stack
					for (j in stack)
					{
						if (j == i)
						{
							stack.remove(j);
						}
					}
						
					// Remove from main array
					for (list in aList)
					{
						if (Lambda.has(list, i))
						{
							list.remove(i);
						}
					}
				}
			}
		}
	}			
}

class Member
{
	public var key:Int;
	public var id:Int;
	
	public var bottom:Dynamic;
	public var upper:Dynamic;
	public var left:Dynamic;
	public var right:Dynamic;
	
	public function new(id, key)
	{
		this.id = id;
		this.key = key;
	}
	
	public function checkRelations(listpos, arraypos)
	{		
		// BY ARRAY POST
		// Check to the bottom
		if (arraypos == 4)
		{
			this.bottom = null;
			
			if (Main.aList[listpos][arraypos - 1] != null && Main.aList[listpos][arraypos - 1].key == this.key )
			{
				this.upper = Main.aList[listpos][arraypos - 1].id;
			} else {
				this.upper = null;
			}
		} else if (arraypos == 0)
		{
			this.upper = null;
			
			if (Main.aList[listpos][arraypos + 1] != null && Main.aList[listpos][arraypos + 1].key == this.key )
			{
				this.bottom = Main.aList[listpos][arraypos + 1].id;
			} else {
				this.bottom = null;
			}
		} else {
			if (Main.aList[listpos][arraypos + 1] != null && Main.aList[listpos][arraypos + 1].key == this.key )
			{
				this.bottom = Main.aList[listpos][arraypos + 1].id;
			} else {
				this.bottom = null;
			}
				
			if (Main.aList[listpos][arraypos - 1] != null && Main.aList[listpos][arraypos - 1].key == this.key )
			{
				this.upper = Main.aList[listpos][arraypos - 1].id;
			} else {
				this.upper = null;
			}
		}
		
		// BY LISTPOS
		// Check to the left
		if (listpos == 0)
		{
			this.left = null;
			
			if ( Main.aList[listpos + 1][arraypos] != null && Main.aList[listpos + 1][arraypos].key == this.key)
			{
				this.right = Main.aList[listpos + 1][arraypos].id;
			} else {
				this.right = null;
			}
		} else if (listpos == 4)
		{
			this.right = null;
			
			if( Main.aList[listpos - 1][arraypos] != null && Main.aList[listpos - 1][arraypos].key == this.key )
			{
					this.left = Main.aList[listpos - 1][arraypos].id;
			}
		} else {
			if( Main.aList[listpos + 1][arraypos] != null && Main.aList[listpos + 1][arraypos].key == this.key )
			{
					this.right = Main.aList[listpos + 1][arraypos].id;
			} else {
				this.right = null;
			}
			
			if ( Main.aList[listpos - 1][arraypos] != null && Main.aList[listpos - 1][arraypos].key == this.key)
			{
				this.left = Main.aList[listpos - 1][arraypos].id;
			} else {
				this.left = null;
			}
		}
	}
}
