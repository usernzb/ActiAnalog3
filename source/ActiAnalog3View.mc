using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;
using Toybox.Activity as Activity;
using Toybox.ActivityMonitor as Act;
using Toybox.Application as App;
using Toybox.Communications as Comm;

class ActiAnalog3View extends Ui.WatchFace {

	var font;
	var isAwake;
	var screenShape;
	var clockFace;
	var activities;
	var flaticon;
	var garmin_blue = 0x007CC3;
	var garmin_light_grey = 0xBBBDBF;
	var garmin_dark_grey = 0x494848;
	var deviceSettings = Sys.getDeviceSettings();
	var screenWidth;
  	var screenHeight;
  	var halfWidth;
  	var halfHeight;
  	var twoPi = Math.PI * 2.0;
  	
  	hidden var BottomScreen = 1;
  	hidden var HourHandColor = 0xBBBDBF;
  	hidden var MinuteHandColor = 0x007CC3;
  	hidden var SecondsHandColor = 0xFF0000;
  	hidden var Font = 0;
  	hidden var TimeFont;
  	hidden var DateFont;
  	hidden var ActFont;
  	hidden var bkgdColor = 0x000000;
  	hidden var showHands = true;
  	hidden var showSeconds = true;
  	hidden var TimeColor = 0xFFFFFF;
  	hidden var DateColor = 0xFFFFFF;
  	hidden var ActColor = 0xFFFFFF;
  	hidden var Numeral = 0xBBBDBF;
  	hidden var FiveNumeral = 0xFFFFFF;
  	hidden var DateFormat = 11;
  	
  	hidden var today = null;
	hidden var year = 0;
	hidden var month = 0;
	hidden var day = 0;
	hidden var dayOfWeek = null;
	
	hidden var timeFormat = "$1$$2$";
	hidden var hoursFormat = "%d";
	hidden var minutesFormat = "%02d";
	
	hidden var DateTextLeft = "";
	hidden var DateTextRight = "";
	
function initialize() {
		WatchFace.initialize();
		screenShape = deviceSettings.screenShape;
	}

function onLayout(dc) {
		//font = Ui.loadResource(Rez.Fonts.id_font_black_diamond);
		//timefont = Ui.loadResource(Rez.Fonts.fontAgencyNormal);
		activities = Ui.loadResource(Rez.Fonts.id_activities);
		flaticon = Ui.loadResource(Rez.Fonts.id_flaticon);
	}

	function drawHand(dc, angle, length, width, endWidth) {
	// Map out the coordinates of the watch hand
		var halfEndWidth; 
		var coords;
		var result = new [4];
		var centerX = dc.getWidth() / 2;
		var centerY = dc.getHeight() / 2;
		var cos = Math.cos(angle);
		var sin = Math.sin(angle);

		if(endWidth > 0)
		{
			halfEndWidth = endWidth / 2;
		}
		else
		{
			halfEndWidth = 0;
		}
		
		coords = [[-(width / 2),0], [-halfEndWidth, -length], [halfEndWidth, -length], [width / 2, 0]];

	// Transform the coordinates
		for (var i = 0; i < 4; i += 1)
		{
			var x = (coords[i][0] * cos) - (coords[i][1] * sin);
			var y = (coords[i][0] * sin) + (coords[i][1] * cos);
			result[i] = [centerX + x, centerY + y];
		}

	// Draw the polygon
			dc.fillPolygon(result);
			dc.fillPolygon(result);
	}

    function drawHands(clockTime, dc, screenWidth, screenHeight) {
        var hourHand;
        var minuteHand;
        var secondHand;
        var secondTail;
        var timeString = format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
		var timeFormat = "$1$:$2$";
		var clockTime = Sys.getClockTime();
        var hours = clockTime.hour;

	if (showHands == true) {
        
        // Draw the hour. Convert it to minutes and compute the angle.
        hourHand = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHand = hourHand / (12 * 60.0);
        hourHand = hourHand * Math.PI * 2;
        dc.setColor(HourHandColor, Gfx.COLOR_TRANSPARENT);
        drawHand(dc, hourHand, 65, 12, 4); 
        
        // Draw the minute
        minuteHand = (clockTime.min / 60.0) * Math.PI * 2;
        dc.setColor(MinuteHandColor, Gfx.COLOR_TRANSPARENT);
        drawHand(dc, minuteHand, 110, 14, 6);
        
        // Draw the second
        if (showSeconds == true)
        {
            timeString += ":" + clockTime.sec.format("%02d");
            dc.setColor(SecondsHandColor, Gfx.COLOR_TRANSPARENT);
            secondHand = (clockTime.sec / 60.0) * Math.PI * 2;
            secondTail = secondHand - Math.PI;
            drawHand(dc, secondHand, 110, 8, 2);
            drawHand(dc, secondTail, 30, 8, 8);
        }
        else if (isAwake)
        {
            timeString += ":" + clockTime.sec.format("%02d");
            dc.setColor(SecondsHandColor, Gfx.COLOR_TRANSPARENT);
            secondHand = (clockTime.sec / 60.0) * Math.PI * 2;
            secondTail = secondHand - Math.PI;
            drawHand(dc, secondHand, 110, 8, 2);
            drawHand(dc, secondTail, 30, 8, 8);
        }
        
        // Draw the arbor
        dc.setColor(MinuteHandColor,Gfx.COLOR_RED);
        dc.fillCircle(halfWidth, halfHeight, 10);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.fillCircle(halfWidth, halfHeight, 7);
        dc.setColor(HourHandColor, Gfx.COLOR_WHITE);
        dc.fillCircle(halfWidth, halfHeight, 4);
	}
        
		//Draw Time
        dc.setColor(TimeColor, Gfx.COLOR_TRANSPARENT);        
        
        if (!Sys.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (App.getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        
        timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
        if (Font==0) //54
        {dc.drawText(halfWidth, 20, Gfx.FONT_NUMBER_HOT, timeString, Gfx.TEXT_JUSTIFY_CENTER);}
        if (Font==1)
        {//TimeFont = Ui.loadResource(Rez.Fonts.fontFutura76);
        dc.drawText(halfWidth, 30, Ui.loadResource(Rez.Fonts.TimeFont), timeString, Gfx.TEXT_JUSTIFY_CENTER);}
        else {}
    }

// Draw Stats
	function drawStats(dc, screenWidth, screenHeight){
		dc.setColor(ActColor, Gfx.COLOR_TRANSPARENT);
		drawActivityInfo(dc, screenWidth, screenHeight);
		drawHeartRate(dc, screenWidth, screenHeight);
		drawBatteryStat(dc);
		drawAlt(dc, screenWidth, screenHeight-2);
		drawDoNotDisturb(dc, screenWidth, screenHeight);
		drawAlarms(dc, screenWidth, screenHeight);
		drawNotifications(dc, screenWidth, screenHeight);
		drawConnectivity(dc, screenWidth, screenHeight);
	}

//Draw Activity	
	function drawActivityInfo(dc, screenWidth, screenHeight) {
		var info = Act.getInfo();
		var activity = ActivityMonitor.getInfo();
		var distKm = info.distance.toFloat() / 100000; // convert from cm to km
		var distmi = info.distance.toFloat() / 160934; // convert from cm to mi
		var stepPer = (activity.steps*100/activity.stepGoal);
		//var km = dc.drawText(halfWidth-46, halfHeight+5, Gfx.FONT_TINY, distKm.format( "%.01f" ), Gfx.TEXT_JUSTIFY_RIGHT)+
		//	dc.drawText(halfWidth-20, halfHeight+11, Gfx.FONT_XTINY, "km", Gfx.TEXT_JUSTIFY_RIGHT);

		//dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
	//Draw Distance
	//19 XTiny
	//19 Tiny
		if( deviceSettings.distanceUnits == 0) //metric
			{dc.drawText(halfWidth-42, halfHeight+5, Gfx.FONT_TINY, distKm.format( "%.01f" ), Gfx.TEXT_JUSTIFY_RIGHT);
			dc.drawText(halfWidth-16, halfHeight+11, Gfx.FONT_XTINY, "km", Gfx.TEXT_JUSTIFY_RIGHT);}
		else	//
			{dc.drawText(halfWidth-39, halfHeight+5, Gfx.FONT_TINY, distmi.format( "%.01f" ), Gfx.TEXT_JUSTIFY_RIGHT);
			dc.drawText(halfWidth-16, halfHeight+11, Gfx.FONT_XTINY, "mi", Gfx.TEXT_JUSTIFY_RIGHT);}
		
		if (stepPer >= 100)
			{dc.drawText(halfWidth, halfHeight+13, flaticon, "s", Gfx.TEXT_JUSTIFY_CENTER);}
		else {}
	//Step Percentage
		{dc.drawText(halfWidth-16, halfHeight+25, Gfx.FONT_TINY, stepPer+"%", Gfx.TEXT_JUSTIFY_RIGHT);}
	//Step Count
		dc.drawText(halfWidth+16, halfHeight+5, Gfx.FONT_TINY, info.steps.format( "%d" ), Gfx.TEXT_JUSTIFY_LEFT);   
	//Foors Climbed
		dc.drawText(halfWidth+16, halfHeight+25, Gfx.FONT_TINY, info.floorsClimbed.format( "%d" )+"/"+info.floorsClimbedGoal, Gfx.TEXT_JUSTIFY_LEFT);
	}

	//Draw Bottom Screen (None, Calories, Altitude (meters or feet))
	function drawAlt(dc, screenWidth, screenHeight)
	{
		var info = Activity.getActivityInfo();
		var monitor = Act.getInfo();
		var altfeet = info.altitude*3.28084;
		var string;
		
		dc.setColor(ActColor, Gfx.COLOR_TRANSPARENT);
		//string = activityInfo.calories.toString() + "kcal";
		
		if (BottomScreen==3)
		{dc.drawText(halfWidth, halfHeight+70, Gfx.FONT_XTINY, altfeet.format( "%d" )+"'", Gfx.TEXT_JUSTIFY_CENTER);}
		else if (BottomScreen==2)
		{dc.drawText(halfWidth, halfHeight+70, Gfx.FONT_XTINY, info.altitude.format( "%d" )+"m", Gfx.TEXT_JUSTIFY_CENTER);}
		else if (BottomScreen==1)
		{dc.drawText(halfWidth, halfHeight+70, Gfx.FONT_XTINY, monitor.calories+"kCal", Gfx.TEXT_JUSTIFY_CENTER);}
		else if (BottomScreen==0)
		{}
	}

// Heart rate
	function drawHeartRate(dc, screenWidth, screenHeight) {
		var tempDrawable;
		var tempObject = Act.getHeartRateHistory(1, true);
		var heartimg;

	// Load bitmap of heart icon
		var heartimage = Rez.Drawables.l_heartrate;
		var bitmap = Ui.loadResource(heartimage);

		//dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		dc.drawBitmap(halfWidth-30, halfHeight+55, bitmap);
		tempObject = tempObject.next();

		var heartrate = tempObject.heartRate;

		if (heartrate == 255) {
			heartrate = 0;
		}

		tempDrawable = View.findDrawableById("l_heartrate");
		dc.drawText(halfWidth-30, halfHeight+45, Gfx.FONT_TINY, heartrate, Gfx.TEXT_JUSTIFY_RIGHT);
	}

// Battery Status Bar \\	
	function drawBatteryStat(dc) {
		//Battery Percentage
		var batString = Lang.format("$1$%", [Sys.getSystemStats().battery.format("%01d")]);
		dc.drawText(136, 165, Gfx.FONT_TINY, batString, Gfx.TEXT_JUSTIFY_LEFT);
		
		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		var batboxend = dc.drawRectangle(128, 180, 2, 4);
		var batbox = dc.drawRoundedRectangle(112, 177, 16, 10, 2.9);

	// Get the current Battery percentage
		var batStat = Sys.getSystemStats().battery;	

	// Change to percentage width
		var batBar = (0.14)*batStat;   
	
	// draw in exchange with battery status
		if (batStat<=10) { 
				dc.setColor(Gfx.COLOR_DK_RED,Gfx.COLOR_WHITE);
				dc.drawRectangle(113,178,batBar,8);
				dc.fillRectangle(113,178,batBar,8);
		}
		else if (batStat <=15) { 
				dc.setColor(Gfx.COLOR_RED,Gfx.COLOR_WHITE);
				dc.drawRectangle(113,178,batBar,8);
				dc.fillRectangle(113,178,batBar,8);
		}
		else if (batStat <=30) { 
				dc.setColor(Gfx.COLOR_ORANGE,Gfx.COLOR_WHITE);
				dc.drawRectangle(113,178,batBar,8);
				dc.fillRectangle(113,178,batBar,8);
		}
		else if (batStat <50) { 
				dc.setColor(Gfx.COLOR_YELLOW,Gfx.COLOR_WHITE);
				dc.drawRectangle(113,178,batBar,8);
				dc.fillRectangle(113,178,batBar,8);
		}
		else if (batStat <=50) { 
				dc.setColor(Gfx.COLOR_GREEN,Gfx.COLOR_WHITE);
				dc.drawRectangle(113,178,batBar,8);
				dc.fillRectangle(113,178,batBar,8);
		}
		else{
    			dc.setColor(Gfx.COLOR_DK_GREEN,Gfx.COLOR_WHITE);
				dc.drawRectangle(113,178,batBar,8);
				dc.fillRectangle(113,178,batBar,8);
		}
		//dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_TRANSPARENT);
	}
    
// Draw Do Not Disturb
	function drawDoNotDisturb(dc, screenWidth, screenHeight) {
	var dndIcon;
	var doNotDisturb = deviceSettings.doNotDisturb;
			
	if (doNotDisturb == true) {
			dndIcon = Ui.loadResource(Rez.Drawables.dnd);
			dc.drawBitmap(25, halfHeight-12.5, dndIcon);   
		}
		else {
        }
	}
		
// Draw Alarms 
	function drawAlarms(dc, screenWidth, screenHeight) {
		var alarmIcon;
		var alarmcount = deviceSettings.alarmCount;

		if (alarmcount>0) {
			alarmIcon = Ui.loadResource(Rez.Drawables.alarm);
			dc.drawBitmap(50, halfHeight-12.5, alarmIcon);
		}
		else {
		}
	}
	
// Draw Notifications
	function drawNotifications(dc, screenWidth, screenHeight) {
		var mIconm; 
		var mIconYm;
		var count = deviceSettings.notificationCount;

		dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_TRANSPARENT);

		if(count>0) {
			dc.drawText(173, halfHeight-15, Gfx.FONT_XTINY, count, Gfx.TEXT_JUSTIFY_RIGHT);
			mIconm = Ui.loadResource(Rez.Drawables.message);
			dc.drawBitmap(176, halfHeight-10, mIconm);
		}
		else {
		}
	}
	
// Draw Connectivity
	function drawConnectivity(dc, screenWidth, screenHeight) {
		var btIcon; 

		dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);  

		if( deviceSettings.phoneConnected == true) {
			btIcon = Ui.loadResource(Rez.Drawables.bluetooth);
			dc.drawBitmap(200, halfHeight-15, btIcon);   	
		} 
		else {
		}
	}

function onUpdate(dc) {
        var clockTime = Sys.getClockTime();        
        var now = Time.now();        
        var dateLong = Calendar.info(now, Time.FORMAT_LONG);
        var targetDc = null;
        
        today = Calendar.info(Time.now(), Time.FORMAT_MEDIUM);
		year = today.year;
		month = today.month;			
		day = today.day;	
		dayOfWeek = today.day_of_week;

		targetDc = dc;
		
		screenWidth = targetDc.getWidth();
    	screenHeight = targetDc.getHeight();
    	halfWidth = screenWidth / 2;
    	halfHeight = screenHeight / 2;

        // Clear the screen
        targetDc.setColor(bkgdColor, Graphics.COLOR_TRANSPARENT);
    	targetDc.fillCircle(screenWidth/2, screenHeight/2, 122);

        //Draw clock face
        //dc.drawBitmap( 0, 0, clockFace);        

		loadAppSettings();

        drawStats(dc, screenWidth, screenHeight);
		drawHands(clockTime, dc, screenWidth, screenHeight);
		//drawDate(dateLong, dc, screenWidth);
		drawNumerals (targetDc);
		drawDate(dc);
}

function loadAppSettings() {

		// Load specified colors from user SETTINGS, use XML properties
		BottomScreen = App.getApp().getProperty("BottomScreen");
		HourHandColor = App.getApp().getProperty("HourHandColor");
		MinuteHandColor = App.getApp().getProperty("MinuteHandColor");
		SecondsHandColor = App.getApp().getProperty("SecondsHandColor");
		Font = App.getApp().getProperty("Font");
		bkgdColor = App.getApp().getProperty("bkgdColor");
		showHands = App.getApp().getProperty("showHands");
		showSeconds = App.getApp().getProperty("showSeconds");
		TimeColor = App.getApp().getProperty("TimeColor");
		DateColor = App.getApp().getProperty("DateColor");
		ActColor = App.getApp().getProperty("ActColor");
		Numeral = App.getApp().getProperty("Numeral");
		FiveNumeral = App.getApp().getProperty("FiveNumeral");
		DateFormat = App.getApp().getProperty("DateFormat");
    }
    
    /** Draw the numerals aroud the face. */
	function drawNumerals (dc) {
    dc.setColor (garmin_light_grey, Graphics.COLOR_TRANSPARENT);
    
    	dc.setColor(MinuteHandColor,Gfx.COLOR_RED);
        dc.drawCircle(120, 119.5, 117);
    
    	var wExtent = screenWidth / 2.18; 
    	var hExtent = screenHeight / 2.18;

    	for (var i = 1; i <= 60; i++) {
      	var angle = twoPi * i / 60.0; 
      	var x = halfWidth - Math.sin (angle) * wExtent; 
      	var y = halfHeight - Math.cos (angle) * hExtent; 

		if (showHands == true)  //28 Large
		{
      		{    	
      		if (i==5 or i==10 or i==15 or i==20 or i==25 or i==30 or i==35 or i==40
      		or i==45 or i==50 or i==55 or i==60)
      		{dc.setColor (FiveNumeral, Graphics.COLOR_TRANSPARENT);
      		dc.drawText (x+1, y-27, Graphics.FONT_LARGE, ".", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_CENTER);  }
        	else
        	{dc.setColor (Numeral, Graphics.COLOR_TRANSPARENT);
      		dc.drawText (x+1, y-24, Graphics.FONT_TINY, ".", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_CENTER);}
        	}
		}
	}
}
	
	function drawDate(dc) {
	dc.setColor (DateColor, Graphics.COLOR_TRANSPARENT);
		switch(DateFormat) {
		    	case 1: // day of week | dd
		    		DateTextLeft = dayOfWeek.toString();
		    		DateTextRight = day.format("%02d").toString();
		    		break;		
		    	case 2: // day of week | dd.mm
		    		month = (Calendar.info(Time.now(), Time.FORMAT_SHORT)).month;
		    		DateTextLeft = dayOfWeek.toString();
		    		DateTextRight = day.format("%02d").toString() + "." + month.format("%02d").toString();
		    		break;		
		    	case 3: // day of week | mm.dd
		    		month = (Calendar.info(Time.now(), Time.FORMAT_SHORT)).month;
		    		DateTextLeft = dayOfWeek.toString();
		    		DateTextRight = month.format("%02d").toString() + "." + day.format("%02d").toString();
		    		break;				    				    		
				case 4: // month | dd
		    		DateTextLeft = month.toString();
		    		DateTextRight = day.format("%02d").toString();
		    		break;
				case 5: // (d)d | month
		    		DateTextLeft = day.format(hoursFormat).toString();
		    		DateTextRight = month.toString();
		    		break;	
				case 6: // dd | mm
					month = (Calendar.info(Time.now(), Time.FORMAT_SHORT)).month;
		    		DateTextLeft = day.format("%02d").toString();
		    		DateTextRight = month.format("%02d").toString();
		    		break;		
				case 7: // mm | dd
					month = (Calendar.info(Time.now(), Time.FORMAT_SHORT)).month;
		    		DateTextLeft = month.format("%02d").toString();
		    		DateTextRight = day.format("%02d").toString();
		    		break;				    			    			    		
		    	case 8: // dd.mm | yyyy
		    		month = (Calendar.info(Time.now(), Time.FORMAT_SHORT)).month;
		    		DateTextLeft = day.format("%02d").toString() + "." + month.format("%02d").toString();
		    		DateTextRight = year.toString();
		    		break;
		    	case 9: // yyyy | mm.dd
		    		month = (Calendar.info(Time.now(), Time.FORMAT_SHORT)).month;
		    		DateTextLeft = year.toString();
		    		DateTextRight = month.format("%02d").toString() + "." + day.format("%02d").toString();
		    		break;
		    	case 10:	// mm.dd | yyyy
		    		month = (Calendar.info(Time.now(), Time.FORMAT_SHORT)).month;
		    		DateTextLeft = month.format("%02d").toString() + "." + day.format("%02d").toString();
		    		DateTextRight = year.toString();
		    		break;
		    	case 11:	// day of week | dd month
		    		month = (Calendar.info(Time.now(), Time.FORMAT_LONG)).month;
		    		DateTextLeft = dayOfWeek.toString();
		    		DateTextRight = month.toString() + " " + day.format("%02d").toString();
		    		break;
		    	default: // Hide
		    		DateTextLeft = "";
		    		DateTextRight = "";
		 }
		 if (Font==0)
		 {dc.drawText(halfWidth,75,dc.FONT_TINY,DateTextLeft+" "+DateTextRight,Gfx.TEXT_JUSTIFY_CENTER);}
		 //if (Font==1)
		// {dc.drawText(halfWidth,75,Ui.loadResource(Rez.Fonts.TimeFont),DateTextLeft+" "+DateTextRight,Gfx.TEXT_JUSTIFY_CENTER);}
    }
function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

function onExitSleep() {
        isAwake = true;
    }
}
