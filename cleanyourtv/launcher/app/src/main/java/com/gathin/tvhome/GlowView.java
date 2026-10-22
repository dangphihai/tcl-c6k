package com.gathin.tvhome;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.view.View;

public class GlowView extends View {
    private final Paint glow = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF rect = new RectF();
    private int glowColor = 0xFFFFFF;

    public GlowView(Context context, AttributeSet attrs) {
        super(context, attrs);
        glow.setStyle(Paint.Style.STROKE);
    }

    public void setGlowColor(int color) {
        this.glowColor = (color != 0) ? (color & 0xFFFFFF) : 0xFFFFFF;
        invalidate();
    }

    @Override
    protected void onDraw(Canvas canvas) {
        float density = getResources().getDisplayMetrics().density;
        float inset = 8f * density;
        rect.set(inset, inset, getWidth() - inset, getHeight() - inset);
        float radius = 16f * density;
        int rings = 12;
        float step = inset / rings;
        glow.setStrokeWidth(step + 0.6f);
        for (int i = 0; i < rings; i++) {
            float o = step * (i + 0.5f);
            float t = 1f - (float) i / rings;
            int alpha = Math.round(0x80 * t * t);
            glow.setColor((alpha << 24) | glowColor);
            canvas.drawRoundRect(rect.left - o, rect.top - o, rect.right + o, rect.bottom + o, radius + o, radius + o, glow);
        }
    }
}
