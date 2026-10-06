import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

fig = plt.figure(figsize=(22, 14), dpi=300)
ax = fig.add_subplot(111)
ax.set_xlim(0, 2200)
ax.set_ylim(0, 1400)
ax.axis('off')

fig.patch.set_facecolor('#ffffff')
ax.set_facecolor('#ffffff')

# System Boundary Box
boundary = patches.FancyBboxPatch((310, 80), 1580, 1240, boxstyle="square,pad=0.0",
                                  facecolor='#ffffff', edgecolor='#000000', linewidth=2.0)
ax.add_patch(boundary)

# System Title Header
ax.text(1100, 1295, "Uzhavan Platform – UML Use Case Diagram",
        ha='center', va='center', fontsize=18, fontweight='bold', color='#000000')
ax.text(1100, 1265, "Agro-Machine Rental Marketplace with On-Device Multilingual Voice & Smart Diesel Audit",
        ha='center', va='center', fontsize=11, fontstyle='italic', color='#333333')
ax.plot([380, 1820], [1245, 1245], color='#000000', lw=1.0, linestyle='--')

# Draw Stick Figure Actor
def draw_actor(ax, x, y, name, role):
    head_r = 18
    # Head
    head = patches.Circle((x, y + 45), head_r, facecolor='#ffffff', edgecolor='#000000', lw=2.0)
    ax.add_patch(head)
    # Body
    ax.plot([x, x], [y + 27, y - 25], color='#000000', lw=2.0)
    # Arms
    ax.plot([x - 28, x + 28], [y + 12, y + 12], color='#000000', lw=2.0)
    # Hands
    ax.plot([x - 28, x - 35], [y + 12, y - 5], color='#000000', lw=1.8)
    ax.plot([x + 28, x + 35], [y + 12, y - 5], color='#000000', lw=1.8)
    # Legs
    ax.plot([x, x - 22], [y - 25, y - 75], color='#000000', lw=2.0)
    ax.plot([x, x + 22], [y - 25, y - 75], color='#000000', lw=2.0)
    # Labels
    ax.text(x, y - 95, name, ha='center', va='center', fontsize=12, fontweight='bold', color='#000000')
    ax.text(x, y - 115, f"({role})", ha='center', va='center', fontsize=10, fontstyle='italic', color='#333333')

# Draw Use Case Oval
def draw_use_case(ax, cx, cy, w, h, text, is_sub=False):
    bg_color = '#ffffff' if not is_sub else '#f7f7f7'
    oval = patches.FancyBboxPatch((cx - w/2, cy - h/2), w, h,
                                  boxstyle=f"round,pad=0.0,rounding_size={h/2}",
                                  facecolor=bg_color, edgecolor='#000000', linewidth=1.5)
    ax.add_patch(oval)
    lines = text.split('\n')
    if len(lines) == 1:
        ax.text(cx, cy, lines[0], ha='center', va='center', fontsize=9.5, fontweight='bold', color='#000000')
    elif len(lines) == 2:
        ax.text(cx, cy + 6, lines[0], ha='center', va='center', fontsize=9.2, fontweight='bold', color='#000000')
        ax.text(cx, cy - 8, lines[1], ha='center', va='center', fontsize=8.8, fontweight='bold', color='#000000')

# ==================== ACTORS ====================
# Left Side
draw_actor(ax, 140, 950, "Farmer", "Cultivator")
draw_actor(ax, 140, 360, "Village Agent", "Facilitator")

# Right Side
draw_actor(ax, 2060, 950, "Machine Owner", "Operator")
draw_actor(ax, 2060, 360, "Platform Admin", "Governance")

# Actor Generalization (Village Agent specializes Farmer)
ax.plot([140, 140], [480, 810], color='#000000', lw=1.6)
ax.plot([140, 130], [810, 785], color='#000000', lw=1.6)
ax.plot([140, 150], [810, 785], color='#000000', lw=1.6)
ax.plot([130, 150], [785, 785], color='#000000', lw=1.6)

# ==================== COLUMN 1: FARMER & AGENT USE CASES (X = 570) ====================
c1_x = 570
w_c1 = 280
h_c1 = 44

# Farmer Use Cases
uc_f1 = (c1_x, 1190, w_c1, h_c1, "Register / Login via OTP")
uc_f2 = (c1_x, 1115, w_c1, h_c1, "Search Machinery by Proximity")
uc_f3 = (c1_x, 1040, w_c1, h_c1, "Speak Tamil Voice Query")
uc_f4 = (c1_x, 965, w_c1, h_c1, "Reserve Machine Slot (Atomic Lock)")
uc_f5 = (c1_x, 890, w_c1, h_c1, "View Rain & Weather Alerts")
uc_f6 = (c1_x, 815, w_c1, h_c1, "Inspect Diesel Audit Baseline")
uc_f7 = (c1_x, 740, w_c1, h_c1, "Settle Payment (COD / UPI)")
uc_f8 = (c1_x, 665, w_c1, h_c1, "Rate Equipment & Operator")

# Agent Use Cases
uc_a1 = (c1_x, 520, w_c1, h_c1, "Assisted Booking for Elders")
uc_a2 = (c1_x, 445, w_c1, h_c1, "Schedule Multi-Farmer Cluster")
uc_a3 = (c1_x, 370, w_c1, h_c1, "Verify Field Equipment Arrival")
uc_a4 = (c1_x, 295, w_c1, h_c1, "Manage Offline Cash Ledger")

for uc in [uc_f1, uc_f2, uc_f3, uc_f4, uc_f5, uc_f6, uc_f7, uc_f8, uc_a1, uc_a2, uc_a3, uc_a4]:
    draw_use_case(ax, uc[0], uc[1], uc[2], uc[3], uc[4])

# Section Divider Header in Col 1
ax.text(c1_x, 575, "--- Community Assisted Portal ---", ha='center', va='center',
        fontsize=9, fontweight='bold', fontstyle='italic', color='#555555')

# ==================== COLUMN 2: SHARED CORE & ENGINES (X = 1100) ====================
c2_x = 1100
w_c2 = 290
h_c2 = 44

uc_m1 = (c2_x, 1160, w_c2, h_c2, "Authenticate User Token", True)
uc_m2 = (c2_x, 1050, w_c2, h_c2, "Shake-to-Voice Trigger", True)
uc_m3 = (c2_x, 940, w_c2, h_c2, "On-Device NLP Speech Parser", True)
uc_m4 = (c2_x, 815, w_c2, h_c2, "Calculate Fuel Baseline Ratio", True)
uc_m5 = (c2_x, 700, w_c2, h_c2, "Fetch Open-Meteo Rain Radar", True)
uc_m6 = (c2_x, 480, w_c2, h_c2, "Resolve Diesel Fuel Disputes", True)
uc_m7 = (c2_x, 370, w_c2, h_c2, "Manage Village Service Cluster", True)

for uc in [uc_m1, uc_m2, uc_m3, uc_m4, uc_m5, uc_m6, uc_m7]:
    draw_use_case(ax, uc[0], uc[1], uc[2], uc[3], uc[4], uc[5])

ax.text(c2_x, 1210, "Core Verification & Edge Telemetry", ha='center', va='center',
        fontsize=10.5, fontweight='bold', color='#111111')

# ==================== COLUMN 3: OWNER & ADMIN USE CASES (X = 1630) ====================
c3_x = 1630
w_c3 = 290
h_c3 = 44

# Owner Use Cases
uc_o1 = (c3_x, 1190, w_c3, h_c3, "Onboard Machinery & Specs")
uc_o2 = (c3_x, 1115, w_c3, h_c3, "Configure Hourly & Acre Rates")
uc_o3 = (c3_x, 1040, w_c3, h_c3, "Manage Slot Availability Calendar")
uc_o4 = (c3_x, 965, w_c3, h_c3, "Accept / Reject Rental Requests")
uc_o5 = (c3_x, 890, w_c3, h_c3, "Log Completed Acres & Fuel")
uc_o6 = (c3_x, 815, w_c3, h_c3, "Withdraw Escrow Earnings")

# Admin Use Cases
uc_ad1 = (c3_x, 670, w_c3, h_c3, "Manage Equipment Categories")
uc_ad2 = (c3_x, 595, w_c3, h_c3, "Configure Soil Baseline Constants")
uc_ad3 = (c3_x, 520, w_c3, h_c3, "Monitor Geospatial Fleet")
uc_ad4 = (c3_x, 445, w_c3, h_c3, "Review Analytics Dashboard")
uc_ad5 = (c3_x, 370, w_c3, h_c3, "Generate & Export Reports")
uc_ad6 = (c3_x, 295, w_c3, h_c3, "Audit Immutable Security Logs")

for uc in [uc_o1, uc_o2, uc_o3, uc_o4, uc_o5, uc_o6, uc_ad1, uc_ad2, uc_ad3, uc_ad4, uc_ad5, uc_ad6]:
    draw_use_case(ax, uc[0], uc[1], uc[2], uc[3], uc[4])

ax.text(c3_x, 725, "--- Platform Governance & Controls ---", ha='center', va='center',
        fontsize=9, fontweight='bold', fontstyle='italic', color='#555555')


# ==================== SOLID ACTOR ASSOCIATION LINES ====================
f_hand = (175, 960)
for uc in [uc_f1, uc_f2, uc_f3, uc_f4, uc_f5, uc_f6, uc_f7, uc_f8]:
    ax.plot([f_hand[0], uc[0] - uc[2]/2], [f_hand[1], uc[1]], color='#000000', lw=1.2)

a_hand = (175, 370)
for uc in [uc_a1, uc_a2, uc_a3, uc_a4]:
    ax.plot([a_hand[0], uc[0] - uc[2]/2], [a_hand[1], uc[1]], color='#000000', lw=1.2)

o_hand = (2025, 960)
for uc in [uc_o1, uc_o2, uc_o3, uc_o4, uc_o5, uc_o6]:
    ax.plot([o_hand[0], uc[0] + uc[2]/2], [o_hand[1], uc[1]], color='#000000', lw=1.2)

ad_hand = (2025, 370)
for uc in [uc_ad1, uc_ad2, uc_ad3, uc_ad4, uc_ad5, uc_ad6]:
    ax.plot([ad_hand[0], uc[0] + uc[2]/2], [ad_hand[1], uc[1]], color='#000000', lw=1.2)

# Platform Admin connects to Resolve Diesel Disputes
ax.plot([ad_hand[0], c2_x + w_c2/2], [ad_hand[1], uc_m6[1]], color='#000000', lw=1.2)

# Village Agent connects to Manage Village Service Cluster
ax.plot([a_hand[0], c2_x - w_c2/2], [a_hand[1], uc_m7[1]], color='#000000', lw=1.2)


# ==================== CLEAN NON-OVERLAPPING STEREOTYPES ====================
def draw_dashed_connector(ax, p1, p2, stereotype, label_pos=None):
    ax.annotate('', xy=p2, xytext=p1,
                arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6",
                                color="#000000", lw=1.2, linestyle='--'))
    lx = (p1[0] + p2[0]) / 2 if label_pos is None else label_pos[0]
    ly = (p1[1] + p2[1]) / 2 if label_pos is None else label_pos[1]
    ax.text(lx, ly, stereotype, ha='center', va='center', fontsize=7.5, fontweight='bold',
            color='#000000', bbox=dict(boxstyle='square,pad=0.2', facecolor='#ffffff', edgecolor='#000000', lw=0.6))

# 1. Register/Login -> Authenticate User (<<include>>)
draw_dashed_connector(ax, (c1_x + w_c1/2, 1190), (c2_x - w_c2/2, 1160), "<<include>>", (835, 1175))

# 2. Onboard Machinery -> Authenticate User (<<include>>)
draw_dashed_connector(ax, (c3_x - w_c3/2, 1190), (c2_x + w_c2/2, 1160), "<<include>>", (1365, 1175))

# 3. Shake-to-Voice -> Speak Tamil Voice Query (<<extend>>)
draw_dashed_connector(ax, (c2_x - w_c2/2, 1050), (c1_x + w_c1/2, 1040), "<<extend>>", (835, 1045))

# 4. Speak Tamil Voice Query -> NLP Speech Parser (<<include>>)
draw_dashed_connector(ax, (c1_x + w_c1/2, 1025), (c2_x - w_c2/2, 955), "<<include>>", (835, 990))

# 5. Inspect Diesel Audit -> Calculate Fuel Baseline (<<include>>)
draw_dashed_connector(ax, (c1_x + w_c1/2, 815), (c2_x - w_c2/2, 815), "<<include>>", (835, 815))

# 6. View Rain Alerts -> Fetch Open-Meteo Radar (<<include>>)
draw_dashed_connector(ax, (c1_x + w_c1/2, 885), (c2_x - w_c2/2, 715), "<<include>>", (835, 875))

# 7. Resolve Diesel Disputes -> Calculate Baseline (<<include>>)
draw_dashed_connector(ax, (c2_x, 480 + h_c2/2), (c2_x, 815 - h_c2/2), "<<include>>", (c2_x + 35, 640))

# 8. Assisted Booking -> Reserve Machine Slot (<<extend>>)
# Beautiful orthogonal route along the left margin of Column 1
ax.plot([c1_x - w_c1/2, 385, 385, c1_x - w_c1/2], [520, 520, 965, 965], color='#000000', lw=1.2, linestyle='--')
ax.annotate('', xy=(c1_x - w_c1/2, 965), xytext=(405, 965),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.2, linestyle='--'))
ax.text(385, 740, "<<extend>>", ha='center', va='center', fontsize=7.5, fontweight='bold', rotation=90,
        color='#000000', bbox=dict(boxstyle='square,pad=0.2', facecolor='#ffffff', edgecolor='#000000', lw=0.6))


# ==================== CAPTION & LEGEND ====================
leg_box = patches.FancyBboxPatch((335, 105), 450, 65, boxstyle="square,pad=0.0",
                                 facecolor='#ffffff', edgecolor='#000000', linewidth=1.0, linestyle=':')
ax.add_patch(leg_box)
ax.text(350, 155, "UML Use Case Notation Legend", fontsize=8.5, fontweight='bold', color='#000000')
ax.plot([350, 380], [135, 135], color='#000000', lw=1.2)
ax.text(390, 135, "Actor Association", fontsize=8, color='#222222')
ax.plot([350, 380], [118, 118], color='#000000', lw=1.2, linestyle='--')
ax.text(390, 118, "<<include>> / <<extend>> Relationship", fontsize=8, color='#222222')

# Legend generalization arrow
ax.plot([580, 605], [135, 135], color='#000000', lw=1.4)
ax.plot([605, 595], [135, 142], color='#000000', lw=1.4)
ax.plot([605, 595], [135, 128], color='#000000', lw=1.4)
ax.plot([595, 595], [142, 128], color='#000000', lw=1.4)
ax.text(615, 135, "Actor Generalization", fontsize=8, color='#222222')

# Figure Caption
ax.text(1100, 45, "Fig 4.7: Comprehensive UML Use Case Diagram – Uzhavan Agro-Machine Rental Marketplace",
        ha='center', va='center', fontsize=12, fontweight='bold', fontstyle='italic', color='#000000')

plt.subplots_adjust(left=0.01, right=0.99, top=0.98, bottom=0.02)
out_png = r"d:\Uzhavan\docs\images\use_case_diagram_uzhavan_bw.png"
plt.savefig(out_png, dpi=300, facecolor=fig.get_facecolor(), edgecolor='none', bbox_inches='tight')
print(f"SUCCESS: Generated {out_png}")
