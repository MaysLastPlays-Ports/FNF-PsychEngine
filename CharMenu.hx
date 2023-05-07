// This is completely re-typed out, I did this so I didn't just copy and paste so that HOPEFULLY it works better and doesn't need that many changes.



/* 

IF DOWNLOADING FROM THE CharMenuFiles Folder:

DO NOT FORGET TO RENAME THIS FILE TO "CharMenu.hx"

They are only labeled this way for specific engines 

(if it is necessary to make it for an engine)

*/



package;



import Section.SwagSection;

import Song.SwagSong;



import flixel.FlxG;

import flixel.FlxSprite;

import flixel.addons.display.FlxGridOverlay;

import flixel.group.FlxGroup.FlxTypedGroup;

import flixel.math.FlxMath;

import flixel.text.FlxText;

import flixel.util.FlxColor;

import flixel.effects.FlxFlicker;

import flixel.util.FlxTimer;

import lime.utils.Assets;

import haxe.Json;

import Boyfriend.Boyfriend;

import Character.Character;

import HealthIcon.HealthIcon;

import flixel.ui.FlxBar;

import flixel.tweens.FlxTween;

import flixel.tweens.FlxEase;



// Using for achievements

import Achievements;



import Math;

import StringTools;

import FreeplayState;



class CharMenu extends MusicBeatState{

    // Selectable Character Variables

    var selectableCharacters:Array<String> = ['bf', 'bf-christmas']; // Currently Selectable characters

    var selectableCharactersNames:Array<String> = ['Default Character', 'Boyfriend but Christmas']; // Characters names

    var selectableCharactersColors:Array<FlxColor> = [0xFF00ABC5, 0xFF00ABC5]; // The colors used for the background

    var selectableCharactersOffsets:Array<Array<Int>> = [[10, 10], [35, 10]]; // [x, y]

    

    // Unlockable characters

    var unlockableChars:Array<String> = ['pico-player', 'tankman-player']; // Unlockable Characters

    var unlockableCharsNames:Array<String> = ['Pico', 'UGH']; // Names of unlockable Characters

    var unlockableCharsColors:Array<FlxColor> = [0xFF00DD0F, 0xFF6C6C6C]; // The colors used for the background

    var unlockableCharactersOffsets:Array<Array<Int>> = [[-5, -30], [25, 0]]; // [x, y]

    

    // This is the characters that actually appear on the menu

    var unlockedCharacters:Array<String> = [];

    var unlockedCharactersNames:Array<String> = [];

    var unlockedCharactersColors:Array<FlxColor> = [];

    var unlockedCharactersOffsets:Array<Array<Int>> = [];



    // This'll be used for achievements

    /* This is an example

    [

        ["week3_nomiss", "0"], - This'll unlock the first unlockable character if Week 3 was completed with no misses

        ["week7_nomiss", "1"] - This'll unlock the second unlockable character

    ]

    */

    var achievementUnlocks:Array<Array<String>> = [

        ["week7_nomiss", "1"], 

        ["week3_nomiss", "0"]

    ];



    // Folder locations

    var backgroundFolder:String = 'background'; // The location of the folder storing the characters backgrounds

    var fontFolder:String = 'assets/fonts/'; // Please don't change unless font folder changes, leads to the fonts folder

    var sharedFolder:String = 'shared'; // Please don't change, leads to the shared folder



    // Variables for what is shown on screen

    var curSelected:Int = 0; // Which character is selected

    var icon:HealthIcon; // The healthicon of the selected character

    var menuBG:FlxSprite; // The background

    var bgOverlay:FlxSprite;

    var colorTween:FlxTween = null;

    private var imageArray:Array<Boyfriend> = []; // Array of all the selectable characters

    var selectedCharName:FlxText; // Name of selected character

    var alphaTweens:Array<FlxTween> = [null]; // Copying destinationTweens idea for this



    // Additional Variables

    var alreadySelected:Bool = false; // If the character is already selected

    var ifCharsAreUnlocked:Array<Bool> = FlxG.save.data.daUnlockedChars;



    // Animated Arrows Variables

    var newArrows:FlxSprite;

	
    // Used to not double reset values

    private var alreadyReset:Bool = false;



    // Used for Char Placement

    var charXoffset:Int = 500;

    var tweenTime:Float = 0.35;

    var destinationTweens:Array<FlxTween> = [null];



    // Use for offseting

    #if debug

    var inCharMenuDebug:Bool = false;

    var charMenuDebugText:FlxText;

    #end



    override function create()

    {

        resetCharacterSelectionVars();

        checkFirstSlot();



        // Code to check is an achievement is completed

        for (i in 0...achievementUnlocks.length)

        {

            if (Achievements.isAchievementUnlocked(achievementUnlocks[i][0])) {

                FlxG.save.data.daUnlockedChars[Std.parseInt(achievementUnlocks[i][1])] = true;

            }

            else {

                FlxG.save.data.daUnlockedChars[Std.parseInt(achievementUnlocks[i][1])] = false;

            }

        }



        // Determines if the characters are unlocked

        if (ifCharsAreUnlocked == null) 

        {

            ifCharsAreUnlocked = [false];

            for (i in 0...unlockableChars.length) {

                if (FlxG.save.data.daUnlockedChars != null) {

                    if (FlxG.save.data.daUnlockedChars[i] != null) {

                        ifCharsAreUnlocked[i] = FlxG.save.data.daUnlockedChars[i];

                    }

                } else { // For some reason I had to create a failsafe?

                    FlxG.save.data.daUnlockedChars[i] = false;

                }

            }

        }

        // If the unlocked chars are empty, fill it with defaults

        if (unlockedCharacters == null) 

        {

            unlockedCharacters = selectableCharacters;

        } 

        // If names are empty, fill it with defaults

        if (unlockedCharactersNames == null) 

        {

            unlockedCharactersNames = selectableCharactersNames;

        }

        // If colors are empty, fill it with defaults

        if (unlockedCharactersColors == null)

        {

            unlockedCharactersColors = selectableCharactersColors;

        }

        // If offsets are empty, fill with defaults

        if (unlockedCharactersOffsets == null)

        {

            unlockedCharactersOffsets = selectableCharactersOffsets;

        }



        unlockedCharsCheck();



        // Making sure the background is added first to be in the back and then adding the character names and character images afterwords

        menuBG = new FlxSprite().loadGraphic(Paths.image('noColorBackground', backgroundFolder));

        menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));

        menuBG.updateHitbox();

        menuBG.screenCenter();

        menuBG.color = unlockedCharactersColors[curSelected];

        menuBG.antialiasing = true;

        add(menuBG);



        bgOverlay = new FlxSprite().loadGraphic(Paths.image('bgOverlay', backgroundFolder));

        bgOverlay.setGraphicSize(Std.int(bgOverlay.width * 1.1));

        bgOverlay.updateHitbox();

        bgOverlay.screenCenter();

        bgOverlay.antialiasing = true;

        add(bgOverlay);



        // Adds the chars to the selection

        for (i in 0...unlockedCharacters.length)

        {

            var characterImage:Boyfriend = new Boyfriend(0, 0, unlockedCharacters[i]);

            if (StringTools.endsWith(unlockedCharacters[i], '-pixel'))

                characterImage.scale.set(5.5, 5.5);

            else

                characterImage.scale.set(0.8, 0.8);



            characterImage.screenCenter(XY);

            imageArray.push(characterImage);

            add(characterImage);

        }



        // Character select text at the top of the screen

        var selectionHeader:Alphabet = new Alphabet(0, 50, 'Character Select', true);

        selectionHeader.screenCenter(X);

        add(selectionHeader);

        

        // New Animated Arrows

        newArrows = new FlxSprite();

        newArrows.frames = Paths.getSparrowAtlas('newArrows', 'background');

        newArrows.animation.addByPrefix('idle', 'static', 24, false);

        newArrows.animation.addByPrefix('left', 'leftPress', 24, false);

        newArrows.animation.addByPrefix('right', 'rightPress', 24, false);

        newArrows.antialiasing = true;

        newArrows.screenCenter(XY);

        newArrows.offset.set(0, -45);

        newArrows.animation.play('idle');

        add(newArrows);



        // The currently selected character's name top right

        selectedCharName = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);

        selectedCharName.setFormat(fontFolder + 'vcr.ttf', 32, FlxColor.WHITE, RIGHT);

        selectedCharName.alpha = 0.7;

        add(selectedCharName);



        #if debug

        charMenuDebugText = new FlxText(FlxG.width * 0.7, FlxG.height * 0.8, 0, "", 32);

        charMenuDebugText.setFormat(fontFolder + 'vcr.ttf', 32, FlxColor.WHITE, RIGHT);

        add(charMenuDebugText);

        #end



        initializeChars();

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];



        #if android

        addVirtualPad(LEFT_RIGHT, A_B);

        #end



        super.create();

    }



    override function update(elapsed:Float)

    {

        selectedCharName.text = unlockedCharactersNames[curSelected].toUpperCase();

        selectedCharName.x = FlxG.width - (selectedCharName.width + 10);

        if (selectedCharName.text == '' || selectedCharName.text == null)

        {

            trace('No name');

            selectedCharName.text = '';

        }



        // Must be changed depending on how an engine uses its own controls

        var leftPress = controls.UI_LEFT_P; // Default for Psych

        var rightPress = controls.UI_RIGHT_P; // Default for Psych

        var accepted = controls.ACCEPT  #if android || _virtualpad.buttonA.justPressed #end; // Should be Universal

        var goBack = controls.BACK  #if android || _virtualpad.buttonB.justPressed #end; // Should be Universal



        #if debug

        var debugMode = FlxG.keys.justPressed.E;

        var moveDown = FlxG.keys.justPressed.K;

        var moveUp = FlxG.keys.justPressed.I;

        var moveLeft = FlxG.keys.justPressed.J;

        var moveRight = FlxG.keys.justPressed.L;

        var unlockTank = FlxG.keys.justPressed.T;

        #end

        

        if (!alreadySelected)

        {

            if (leftPress)

            {

                newArrows.offset.set(33, 3);

                newArrows.animation.play('left', true);

                changeSelection(-1);

            }

            if (rightPress)

            {

                newArrows.offset.set(0, 4);

                newArrows.animation.play('right', true);

                changeSelection(1);

            }

            if (accepted)

            {

                alreadySelected = true;

                var daSelected:String = unlockedCharacters[curSelected];

                if (unlockedCharacters[curSelected] != PlayState.SONG.player1)

                    PlayState.SONG.player1 = daSelected;



                FlxFlicker.flicker(imageArray[curSelected], 0);



                // This is to make the audio stop when leaving to PlayState

                FlxG.sound.music.volume = 0;



                // This is used in Psych for playing music by pressing space, but the line below stops it once the PlayState is entered

				FreeplayState.destroyFreeplayVocals();



                new FlxTimer().start(0.75, function(tmr:FlxTimer)

                {

                    // LoadingState.loadAndSwitchState(new PlayState()); // Usual way

                    FlxG.switchState(new PlayState()); // Gonna try this for Psych

                });

            }

            if (goBack)

            {

                if (PlayState.isStoryMode)

                    // LoadingState.loadAndSwitchState(new StoryMenuState());

                    FlxG.switchState(new StoryMenuState());

                else

                    // LoadingState.loadAndSwitchState(new FreeplayState());

                    FlxG.switchState(new FreeplayState());

            }

            #if debug

            if (debugMode)

            {

                inCharMenuDebug = !inCharMenuDebug;

            }

            if (inCharMenuDebug)

            {

                charMenuDebugText.alpha = 1;

                if(moveUp) {unlockedCharactersOffsets[curSelected][1]--; initializeChars();}

                if(moveDown) {unlockedCharactersOffsets[curSelected][1]++; initializeChars();}

                if(moveLeft) {unlockedCharactersOffsets[curSelected][0]--; initializeChars();}

                if(moveRight) {unlockedCharactersOffsets[curSelected][0]++; initializeChars();}

                charMenuDebugText.text = "Current Character's\nMenu Offsets:\nX: " +  unlockedCharactersOffsets[curSelected][0] + "\nY: " + unlockedCharactersOffsets[curSelected][1];

            } else {

                charMenuDebugText.alpha = 0;

            }

            #end



            for (i in 0...imageArray.length)

            {

                if (i == curSelected) {imageArray[i].dance();}

            }



            // Code to replay arrow Idle anim when finished

            if (newArrows.animation.finished == true)

            {

                newArrows.offset.set(0, -45);

                newArrows.animation.play('idle');

            }



            super.update(elapsed);

        }

    }



    function initializeChars()

    {

        for (i in 0...imageArray.length)

        {

            // Sets the unselected characters to a more transparent form

            imageArray[i].alpha = 0.8 - Math.abs(0.15 * (i - curSelected));



            /* 

            These adjustments for Pixel characters may break for different ones, but eh, I am just making it for bf-pixel anyway

            

            Nevermind, Go to CheckFirstSlot() function to add specific offsets to make it fit better

            */

            if (StringTools.endsWith(imageArray[i].curCharacter, '-pixel'))

            {

                imageArray[i].x = (FlxG.width / 2) + ((i - curSelected - 1) * charXoffset) + 475 + unlockedCharactersOffsets[i][0];

                imageArray[i].y = (FlxG.height / 2) - 60 + unlockedCharactersOffsets[i][1];

            }

            else

            {

                imageArray[i].x = (FlxG.width / 2) + ((i - curSelected - 1) * charXoffset) + 250 + unlockedCharactersOffsets[i][0];

                imageArray[i].y = (FlxG.height / 2) - (imageArray[i].height / 2) + unlockedCharactersOffsets[i][1];

                // imageArray[i].screenCenter(Y);

            }

        }



        imageArray[curSelected].alpha = 1;



        unlockedCharsCheck();

        charCheck();

    }



    // Changes the currently selected character

    function changeSelection(changeAmount:Int = 0):Void

    {

        curSelected += changeAmount;

        // This just ensures you don't go over the intended amount

        if (curSelected < 0)

            curSelected = unlockedCharacters.length - 1;

        if (curSelected >= unlockedCharacters.length)

            curSelected = 0;



        for (i in 0...imageArray.length)

        {

            var desiredAlpha:Float = 0;

            if (i == curSelected)

                desiredAlpha = 1;

            else

                desiredAlpha = 0.8 - Math.abs(0.15 * (i - curSelected));

            if (alphaTweens[i] != null) alphaTweens[i].cancel();

            alphaTweens[i] = FlxTween.tween(imageArray[i], {alpha : desiredAlpha}, tweenTime, {ease: FlxEase.sineOut});



            var destinationX:Float = 0;



            /* 

            These adjustments for Pixel characters may break for different ones, but eh, I am just making it for bf-pixel anyway



            Nevermind, Go to CheckFirstSlot() function to add specific offsets to make it fit better

            */

            if (StringTools.endsWith(imageArray[i].curCharacter, '-pixel'))

            {

                destinationX = (FlxG.width / 2) + ((i - curSelected - 1) * charXoffset) + 475 + unlockedCharactersOffsets[i][0];

            }

            else

            {

                destinationX = (FlxG.width / 2) + ((i - curSelected - 1) * charXoffset) + 250 + unlockedCharactersOffsets[i][0];

            }

            // if (moveTween != null) moveTween.cancel();

            if (destinationTweens[i] != null) destinationTweens[i].cancel();

            destinationTweens[i] = FlxTween.tween(imageArray[i], {x : destinationX}, tweenTime, {ease: FlxEase.quadInOut});

        }

        

        unlockedCharsCheck();

        charCheck();

    }



    // Checks for what char is selected and creates an icon for it

    function charCheck()

    {

        remove(icon);



        // menuBG.loadGraphic(Paths.image(unlockedCharactersBGs[curSelected], backgroundFolder));

        if (colorTween != null) colorTween.cancel();

        // colorTween = FlxTween.tween(menuBG, {color : unlockedCharactersColors[curSelected]}, tweenTime);

        colorTween = FlxTween.color(menuBG, tweenTime, menuBG.color, unlockedCharactersColors[curSelected], {ease: FlxEase.sineOut});



        icon = new HealthIcon(unlockedCharacters[curSelected], true);



        // This code is for Psych but if necessary can be use on other engines too

        if (unlockedCharacters[curSelected] == 'bf-car' || unlockedCharacters[curSelected] == 'bf-christmas' || unlockedCharacters[curSelected] == 'bf-holding-gf')

            icon.changeIcon('bf');

        if (unlockedCharacters[curSelected] == 'pico-player')

            icon.changeIcon('pico');

        if (unlockedCharacters[curSelected] == 'tankman-player')

            icon.changeIcon('tankman');



        icon.screenCenter(X);

        icon.setGraphicSize(-4);

        icon.y = ((FlxG.height * 0.9) + 4) - (icon.height / 2) - 20;

        add(icon);

    }

    

    function unlockedCharsCheck()

    {

        // Resets all values to ensure that nothing is broken

        if (!alreadyReset) {

            resetCharacterSelectionVars();

        }



        // Makes this universal value equal the save data

        ifCharsAreUnlocked = FlxG.save.data.daUnlockedChars;



        // If you have managed to unlock a character, set it as unlocked here

        for (i in 0...ifCharsAreUnlocked.length)

        {

            if (ifCharsAreUnlocked[i] == true)

            {

                if (!unlockedCharacters.contains(unlockableChars[i])) {

                    unlockedCharacters.push(unlockableChars[i]);

                }

                if (!unlockedCharactersNames.contains(unlockableCharsNames[i])) {

                    unlockedCharactersNames.push(unlockableCharsNames[i]);

                }

                if (!unlockedCharactersColors.contains(unlockableCharsColors[i])) {

                    unlockedCharactersColors.push(unlockableCharsColors[i]);

                }

                if (!unlockedCharactersOffsets.contains(unlockableCharactersOffsets[i])) {

                    unlockedCharactersOffsets.push(unlockableCharactersOffsets[i]);

                }

            }

        }

    }



    /*

    This is used for the character that is supposed to be in the song, you may want to add your own case.

    It's to ensure that the character is properly offset in the character selection menu

    */

    function checkFirstSlot()

    {

        switch (unlockedCharacters[0])

        {

            case 'bf':

                unlockedCharactersColors[0] = 0xFF00ABC5;

                unlockedCharactersOffsets[0] = [10, 10];

            case 'bf-holding-gf':

                unlockedCharactersOffsets[0] = [10, 10];

            case 'bf-car':

                unlockedCharactersOffsets[0] = [20, -7];

            case 'bf-christmas':

                unlockedCharactersOffsets[0] = [35, 10];

            case 'bf-pixel':

                unlockedCharactersOffsets[0] = [3, 3];

            default:

                unlockedCharactersOffsets[0] = [10, 10];

        }

    }



    function resetCharacterSelectionVars() 

    {

        // Ensures the save data has at least 1 value

        if (FlxG.save.data.daUnlockedChars == null) {FlxG.save.data.daUnlockedChars = [false];}



        // Allows the code to determind if this has already been reset

        alreadyReset = true;



        // Just resets all things to defaults

        ifCharsAreUnlocked = [false];

        destinationTweens = [null];



        // Ensures the characters are reset and that the first one is the default character

        unlockedCharacters = selectableCharacters;

        unlockedCharacters[0] = PlayState.SONG.player1; 



        // Grabs default character names

        unlockedCharactersNames = selectableCharactersNames;



        // Grabs default colors

        unlockedCharactersColors = selectableCharactersColors;



        // Grabs default offsets

        unlockedCharactersOffsets = selectableCharactersOffsets;

    }

}
