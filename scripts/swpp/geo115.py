"""Cam-plate outline for practice problem 11.5 (tangent arcs and lines; pure
geometry, no app calls). Recovered verbatim on 2026-09-16 from the retry-round
worker that wrote it on 2026-09-04: it had lived only in that session's
scratchpad, so 11.5 stopped running once the scratchpad was cleaned up."""
import math
def unit(v):
    l=math.hypot(*v); return (v[0]/l,v[1]/l)
def arcpts(c,r,a0,a1,n=64):
    return [(c[0]+r*math.cos(math.radians(a0+(a1-a0)*i/n)), c[1]+r*math.sin(math.radians(a0+(a1-a0)*i/n))) for i in range(n+1)]
def area(poly):
    s=0
    for i in range(len(poly)):
        x0,y0=poly[i]; x1,y1=poly[(i+1)%len(poly)]; s+=x0*y1-x1*y0
    return abs(s)/2
def circ_int(c1,r1,c2,r2):
    dx,dy=c2[0]-c1[0],c2[1]-c1[1]; d=math.hypot(dx,dy)
    a=(r1*r1-r2*r2+d*d)/(2*d); h=math.sqrt(max(r1*r1-a*a,0))
    mx,my=c1[0]+a*dx/d,c1[1]+a*dy/d
    return [(mx+h*dy/d,my-h*dx/d),(mx-h*dy/d,my+h*dx/d)]
def ang(c,p): return math.degrees(math.atan2(p[1]-c[1],p[0]-c[0]))

def outline(lobe_r=None, flat_x0=-4.0, flat_len=8.0, drop=2.0, side=5.0, a70=70.0, a65=65.0, CL=(-10.0,2.0), rO=7.0, rR=7.0, cR=(7.0,0.0), R5=5.0, xmax=14.0, R3=3.0):
    """Returns list of ('line',a,b) / ('arc',c,r,a0,a1) segments CCW and the polygon."""
    P70=(flat_x0-side, 18-drop); P65=(flat_x0+flat_len+side, 18-drop)
    # 70 deg line through P70 going down-left
    d70=(-math.cos(math.radians(a70)), -math.sin(math.radians(a70)))
    n70=(-d70[1], d70[0])   # left normal of travel direction (points toward... check)
    # distance from CL to the line
    v=(CL[0]-P70[0], CL[1]-P70[1]); dist=abs(v[0]*d70[1]-v[1]*d70[0])
    rL=lobe_r if lobe_r else dist
    # tangent point: foot of perpendicular from CL onto the line, shifted if rL != dist (then not tangent; we just use foot)
    t=v[0]*d70[0]+v[1]*d70[1]; foot=(P70[0]+t*d70[0], P70[1]+t*d70[1])
    T1=(CL[0]+(foot[0]-CL[0])*rL/dist, CL[1]+(foot[1]-CL[1])*rL/dist)
    # R3 fillet between lobe (CL,rL) and (O,rO): centre F, external tangency, lower solution
    F=min(circ_int(CL, rL+R3, (0,0), rO+R3), key=lambda p:p[1])
    TL=(CL[0]+(F[0]-CL[0])*rL/(rL+R3), CL[1]+(F[1]-CL[1])*rL/(rL+R3))
    TO=(F[0]*rO/(rO+R3), F[1]*rO/(rO+R3))
    # R5 tangent to x=xmax and the 65 line through P65 going down-right
    d65=(math.cos(math.radians(-a65)), math.sin(math.radians(-a65)))
    n65=(-d65[1], d65[0])  # (sin65, cos65) points up-right (outside)
    cx5=xmax-R5
    # |(C-P65).n65| = R5, C=(cx5,yc): (cx5-P65x)*n65x + (yc-P65y)*n65y = -R5 (centre inside = negative side)
    yc=P65[1]+(-R5-(cx5-P65[0])*n65[0])/n65[1]
    C5=(cx5,yc); T5=(C5[0]+R5*n65[0], C5[1]+R5*n65[1])
    segs=[]
    segs.append(('line',(flat_x0+flat_len,18),(flat_x0,18)))
    segs.append(('line',(flat_x0,18),P70))
    segs.append(('line',P70,T1))
    a0=ang(CL,T1); a1=ang(CL,TL)
    if a1>a0: a1-=360   # going CCW around the plate = the lobe arc is traversed... the lobe bulges left: from T1 (upper-left) down to TL (lower): that's CCW about CL? T1 at ~160deg, TL at ~-70deg: CCW increasing angle 160->290 (=-70+360)
    a0=ang(CL,T1); a1=ang(CL,TL)%360
    if a1<a0: a1+=360
    segs.append(('arc',CL,rL,a0,a1))
    # fillet: concave, traversed clockwise about F from TL to TO
    b0=ang(F,TL); b1=ang(F,TO)
    while b1>b0: b1-=360
    segs.append(('arc',F,R3,b0,b1))
    c0=ang((0,0),TO)%360; c1=270.0
    if c1<c0: c1+=360
    segs.append(('arc',(0,0),rO,c0,c1))
    segs.append(('line',(0,-rO),(cR[0],-rR)))
    segs.append(('arc',cR,rR,270,360))
    segs.append(('line',(xmax,cR[1]),(xmax,yc)))
    segs.append(('arc',C5,R5,0,ang(C5,T5)))
    segs.append(('line',T5,P65))
    segs.append(('line',P65,(flat_x0+flat_len,18)))
    poly=[]
    for s in segs:
        if s[0]=='line': poly.append(s[1])
        else: poly+=arcpts(s[1],s[2],s[3],s[4])[:-1]
    return segs, poly, dict(rL=rL,F=F,C5=C5,T5=T5,T1=T1,TL=TL,TO=TO)

if __name__=="__main__":
    for kw in [dict(), dict(lobe_r=4.0, flat_x0=-4.16)]:
        segs,poly,info=outline(**kw)
        print(kw, "area %.2f"%area(poly), {k:(round(v,3) if isinstance(v,float) else tuple(round(x,3) for x in v)) for k,v in info.items()})
    A=area(outline()[1])
    cut=50/360*math.pi*(121-49)-4*(1-math.pi/4)
    slot=4*5+math.pi*4
    m2=math.pi*2.45**2*1.6+math.pi*1.2**2*2.4
    m25=math.pi*2.95**2*2.0+math.pi*1.45**2*2.0
    print("cutout",cut,"slot",slot,"m2",m2,"m2.5",m25)
    print("volume", (A-cut-slot)*4-m2-m25, "target 1827.6")
