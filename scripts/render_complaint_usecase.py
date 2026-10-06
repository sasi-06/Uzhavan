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

# Boundary
boundary = patches.FancyBboxPatch((280, 80), 1640, 1240, boxstyle="square,pad=0.0",
                                  facecolor='#ffffff', edgecolor='#000000', linewidth=2.0)
ax.add_patch(boundary)

ax.text(1100, 1290, "Complaint Escalation and Resolution System – Use Case Diagram",
        ha='center', va='center', fontsize=18, fontweight='bold', color='#000000')
ax.plot([400, 1800], [1255, 1255], color='#000000', lw=1.0, linestyle='--')

def draw_actor(ax, x, y, name, role=None):
    head = patches.Circle((x, y + 45), 18, facecolor='#ffffff', edgecolor='#000000', lw=2.0)
    ax.add_patch(head)
    ax.plot([x, x], [y + 27, y - 25], color='#000000', lw=2.0)
    ax.plot([x - 28, x + 28], [y + 12, y + 12], color='#000000', lw=2.0)
    ax.plot([x - 28, x - 35], [y + 12, y - 5], color='#000000', lw=1.8)
    ax.plot([x + 28, x + 35], [y + 12, y - 5], color='#000000', lw=1.8)
    ax.plot([x, x - 22], [y - 25, y - 75], color='#000000', lw=2.0)
    ax.plot([x, x + 22], [y - 25, y - 75], color='#000000', lw=2.0)
    ax.text(x, y - 95, name, ha='center', va='center', fontsize=11, fontweight='bold', color='#000000')
    if role:
        ax.text(x, y - 112, f"({role})", ha='center', va='center', fontsize=9.5, fontstyle='italic', color='#333333')

def draw_use_case(ax, cx, cy, w, h, text):
    oval = patches.FancyBboxPatch((cx - w/2, cy - h/2), w, h,
                                  boxstyle=f"round,pad=0.0,rounding_size={h/2}",
                                  facecolor='#ffffff', edgecolor='#000000', linewidth=1.5)
    ax.add_patch(oval)
    ax.text(cx, cy, text, ha='center', va='center', fontsize=9, fontweight='bold', color='#000000')

# Actors
draw_actor(ax, 140, 1000, "User", "Complainant")
draw_actor(ax, 140, 420, "Staff", "Resolver")
draw_actor(ax, 2060, 850, "Org Admin", "Administrator")
draw_actor(ax, 2060, 250, "Super Admin", "Cross-Org")

# Generalization: Super Admin -> Org Admin
ax.plot([2060, 2060], [360, 710], color='#000000', lw=1.6)
ax.plot([2060, 2050], [710, 685], color='#000000', lw=1.6)
ax.plot([2060, 2070], [710, 685], color='#000000', lw=1.6)
ax.plot([2050, 2070], [685, 685], color='#000000', lw=1.6)

# Left Column (User & Staff Use cases)
w_l = 260
h_l = 42
cx_l = 520

# User UCs
u1 = (cx_l, 1200, w_l, h_l, "Register, Login")
u2 = (cx_l, 1140, w_l, h_l, "Submit Complaint")
u3 = (cx_l, 1080, w_l, h_l, "Upload & Feedback")
u4 = (cx_l, 1020, w_l, h_l, "User Lifecycle & Status")

# Staff UCs
s1 = (cx_l, 640, w_l, h_l, "Complaint Processing")
s2 = (cx_l, 580, w_l, h_l, "Update Complaint Status")
s3 = (cx_l, 520, w_l, h_l, "Add Internal Notes")
s4 = (cx_l, 460, w_l, h_l, "Upload Evidence")
s5 = (cx_l, 400, w_l, h_l, "Start Work Session")
s6 = (cx_l, 340, w_l, h_l, "Apply Response Template")
s7 = (cx_l, 280, w_l, h_l, "Resolve Complaint")

for uc in [u1, u2, u3, u4, s1, s2, s3, s4, s5, s6, s7]:
    draw_use_case(ax, uc[0], uc[1], uc[2], uc[3], uc[4])

# Center Column (Auth & Escalation)
w_m = 250
h_m = 42
cx_m = 1080

m_auth1 = (cx_m, 1180, w_m, h_m, "Authenticate User")
m_auth2 = (cx_m, 580, w_m, h_m, "Authenticate User")
m_esc = (cx_m + 80, 830, w_m, h_m, "Escalate Complaint")
m_man = (cx_m - 120, 890, 210, h_m, "Manual Escalation")
m_auto = (cx_m - 120, 800, 210, h_m, "Auto Escalation")

for uc in [m_auth1, m_auth2, m_esc, m_man, m_auto]:
    draw_use_case(ax, uc[0], uc[1], uc[2], uc[3], uc[4])

ax.text(cx_m, 950, "Escalation Module", ha='center', va='center', fontsize=11, fontweight='bold', color='#111111')

# Right Column (Org Admin & Super Admin)
w_r = 270
h_r = 38
cx_r = 1660

admin_ucs = [
    (cx_r, 1210, w_r, h_r, "Manage Complaints"),
    (cx_r, 1160, w_r, h_r, "Assign Complaint"),
    (cx_r, 1110, w_r, h_r, "Reassign Complaint"),
    (cx_r, 1060, w_r, h_r, "Configure Assignment Rules"),
    (cx_r, 1010, w_r, h_r, "Configure Escalation Rules"),
    (cx_r, 960, w_r, h_r, "Manage Categories"),
    (cx_r, 910, w_r, h_r, "Manage Users & Staff"),
    (cx_r, 860, w_r, h_r, "View Analytics Dashboard"),
    (cx_r, 810, w_r, h_r, "Generate Reports"),
    (cx_r, 760, w_r, h_r, "Export Reports"),
    (cx_r, 710, w_r, h_r, "Process Refund"),
    (cx_r, 660, w_r, h_r, "Manage Templates"),
    (cx_r, 610, w_r, h_r, "Finance & Templates"),
    (cx_r, 260, w_r, h_r, "Manage Organizations"),
    (cx_r, 200, w_r, h_r, "Cross-Organization Governance")
]
for uc in admin_ucs:
    draw_use_case(ax, uc[0], uc[1], uc[2], uc[3], uc[4])

# Lines from Actors
# User Lines
for uc in [u1, u2, u3, u4]:
    ax.plot([175, uc[0] - uc[2]/2], [1010, uc[1]], color='#000000', lw=1.2)

# Staff Lines
for uc in [s1, s2, s3, s4, s5, s6, s7]:
    ax.plot([175, uc[0] - uc[2]/2], [430, uc[1]], color='#000000', lw=1.2)

# Org Admin Lines
for uc in admin_ucs[:13]:
    ax.plot([2025, uc[0] + uc[2]/2], [860, uc[1]], color='#000000', lw=1.2)

# Super Admin Lines
for uc in admin_ucs[13:]:
    ax.plot([2025, uc[0] + uc[2]/2], [260, uc[1]], color='#000000', lw=1.2)

# Dashed Stereotypes
def dash(ax, p1, p2, label, label_pos=None):
    ax.annotate('', xy=p2, xytext=p1,
                arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6",
                                color="#000000", lw=1.2, linestyle='--'))
    lx = (p1[0]+p2[0])/2 if label_pos is None else label_pos[0]
    ly = (p1[1]+p2[1])/2 if label_pos is None else label_pos[1]
    ax.text(lx, ly, label, ha='center', va='center', fontsize=7.5, fontweight='bold',
            color='#000000', bbox=dict(boxstyle='square,pad=0.2', facecolor='#ffffff', edgecolor='#000000', lw=0.6))

dash(ax, (cx_l + w_l/2, 1200), (cx_m - w_m/2, 1180), "<<include>>")
dash(ax, (cx_r - w_r/2, 1210), (cx_m + w_m/2, 1180), "<<include>>")
dash(ax, (cx_l + w_l/2, 580), (cx_m - w_m/2, 580), "<<include>>")
dash(ax, (m_man[0] + 105, m_man[1]), (m_esc[0] - w_m/2, m_esc[1]), "<<extend>>")
dash(ax, (m_auto[0] + 105, m_auto[1]), (m_esc[0] - w_m/2, m_esc[1]), "<<extend>>")
dash(ax, (m_esc[0], m_esc[1] - h_m/2), (m_auth2[0], m_auth2[1] + h_m/2), "<<include>>")

# Figure Caption
ax.text(1100, 45, "Fig: Complaint Escalation and Resolution System – UML Use Case Diagram",
        ha='center', va='center', fontsize=12, fontweight='bold', fontstyle='italic', color='#000000')

plt.subplots_adjust(left=0.01, right=0.99, top=0.98, bottom=0.02)
out_png = r"d:\Uzhavan\docs\images\use_case_diagram_complaint_bw.png"
plt.savefig(out_png, dpi=300, facecolor=fig.get_facecolor(), edgecolor='none', bbox_inches='tight')
print(f"SUCCESS: Generated {out_png}")
