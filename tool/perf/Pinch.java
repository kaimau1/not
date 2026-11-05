import android.os.SystemClock;
import android.view.InputDevice;
import android.view.InputEvent;
import android.view.MotionEvent;
import java.lang.reflect.Method;

public class Pinch {
  static Object im; static Method inject;
  static void send(long down, int action, float cx, float cy, float half, int n) throws Exception {
    MotionEvent.PointerProperties[] pp = new MotionEvent.PointerProperties[n];
    MotionEvent.PointerCoords[] pc = new MotionEvent.PointerCoords[n];
    for (int i = 0; i < n; i++) {
      pp[i] = new MotionEvent.PointerProperties(); pp[i].id = i; pp[i].toolType = MotionEvent.TOOL_TYPE_FINGER;
      pc[i] = new MotionEvent.PointerCoords(); pc[i].pressure = 1; pc[i].size = 1;
      pc[i].x = cx + (i == 0 ? -half : half); pc[i].y = cy;
    }
    MotionEvent e = MotionEvent.obtain(down, SystemClock.uptimeMillis(), action, n, pp, pc, 0, 0, 1, 1, 0, 0, InputDevice.SOURCE_TOUCHSCREEN, 0);
    inject.invoke(im, e, 2);
    e.recycle();
  }
  public static void main(String[] a) throws Exception {
    Class<?> c = Class.forName("android.hardware.input.InputManager");
    im = c.getMethod("getInstance").invoke(null);
    inject = c.getMethod("injectInputEvent", InputEvent.class, int.class);
    float cx = Float.parseFloat(a[0]), cy = Float.parseFloat(a[1]), h0 = Float.parseFloat(a[2]), h1 = Float.parseFloat(a[3]);
    int ms = Integer.parseInt(a[4]), steps = ms / 8;
    long down = SystemClock.uptimeMillis();
    send(down, MotionEvent.ACTION_DOWN, cx, cy, h0, 1);
    send(down, MotionEvent.ACTION_POINTER_DOWN | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT), cx, cy, h0, 2);
    for (int i = 1; i <= steps; i++) {
      send(down, MotionEvent.ACTION_MOVE, cx, cy, h0 + (h1 - h0) * i / steps, 2);
      Thread.sleep(8);
    }
    send(down, MotionEvent.ACTION_POINTER_UP | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT), cx, cy, h1, 2);
    send(down, MotionEvent.ACTION_UP, cx, cy, h1, 1);
  }
}
