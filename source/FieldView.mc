import Toybox.Graphics;
import Toybox.WatchUi;

// FIELD — a monochrome analog watch face.
// FieldView owns the clock and the display geometry; each visual element is
// its own component (see source/components). onUpdate just composes them.
class FieldView extends WatchUi.WatchFace {

    private var mCx, mCy;              // dial center
    private var mLowPower = false;     // true while in low-power / AOD sleep

    // components
    private var mChapterRing;         // minute track + hour indices
    private var mBattery;             // battery sub-dial (12 o'clock)
    private var mWeather;             // weather sub-dial (2–3 o'clock)
    private var mDate;                // date sub-dial (9–10 o'clock)
    private var mSun;                 // sunrise / sunset (6 o'clock, no circle)
    private var mHeart;               // heart-rate sub-dial (7–8 o'clock)
    private var mSteps;               // step-count sub-dial (4–5 o'clock)
    private var mPinion;              // cannon pinion (center boss + pin)
    private var mHands;               // hour / minute / seconds hands

    function initialize() {
        WatchFace.initialize();
        mChapterRing = new ChapterRing();
        mBattery     = new BatteryDial();
        mWeather     = new WeatherDial();
        mDate        = new DateDial();
        mSun         = new SunTimes();
        mHeart       = new HeartDial();
        mSteps       = new StepsDial();
        mPinion      = new CannonPinion();
        mHands       = new Hands();
    }

    function onLayout(dc) {
        mCx = dc.getWidth()  / 2;
        mCy = dc.getHeight() / 2;
    }

    function onUpdate(dc) {
        dc.setColor(Palette.BG, Palette.BG);
        dc.clear();
        if (dc has :setAntiAlias) { dc.setAntiAlias(true); }

        mChapterRing.draw(dc, mCx, mCy);
        mBattery.draw(dc, mCx, mCy);
        mWeather.draw(dc, mCx, mCy);
        mDate.draw(dc, mCx, mCy);
        mSun.draw(dc, mCx, mCy);
        mHeart.draw(dc, mCx, mCy);
        mSteps.draw(dc, mCx, mCy);
        mHands.draw(dc, mCx, mCy, mLowPower);
        mPinion.draw(dc, mCx, mCy);
    }

    function onEnterSleep() { mLowPower = true;  WatchUi.requestUpdate(); }
    function onExitSleep()  { mLowPower = false; WatchUi.requestUpdate(); }
}
