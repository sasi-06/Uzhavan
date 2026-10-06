import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

fig = plt.figure(figsize=(16, 11), dpi=300)
ax = fig.add_subplot(111)
ax.set_xlim(0, 1600)
ax.set_ylim(0, 1100)
ax.axis('off')

fig.patch.set_facecolor('#ffffff')
ax.set_facecolor('#ffffff')

# Title
ax.text(800, 1070, "MongoDB Database Schema – Complaint Escalation and Resolution System",
        ha='center', va='center', fontsize=16, fontweight='bold', color='#000000')
ax.plot([250, 1350], [1050, 1050], color='#000000', lw=1.2, linestyle='--')
ax.text(800, 1035, "Fig 4.4: MongoDB Collections, Document Schemas and Entity Relationships",
        ha='center', va='center', fontsize=10.5, fontstyle='italic', color='#222222')

def draw_table(ax, x, y, w, h, title, fields):
    box = patches.FancyBboxPatch((x, y - h), w, h, boxstyle="square,pad=0.0",
                                 facecolor='#ffffff', edgecolor='#000000', linewidth=1.5)
    ax.add_patch(box)
    
    header_h = 32
    header_box = patches.FancyBboxPatch((x, y - header_h), w, header_h, boxstyle="square,pad=0.0",
                                        facecolor='#f2f2f2', edgecolor='#000000', linewidth=1.5)
    ax.add_patch(header_box)
    
    ax.text(x + w/2, y - 18, title, ha='center', va='center', fontsize=11, fontweight='bold', color='#000000')
    
    curr_y = y - 48
    gap = (h - 45) / max(len(fields), 1)
    for name, ftype in fields:
        is_pk = "[PK]" in ftype
        is_fk = "[FK" in ftype
        fw = 'bold' if (is_pk or is_fk) else 'normal'
        ax.text(x + 10, curr_y, name, ha='left', va='center', fontsize=8.5, fontweight=fw, color='#000000')
        ax.text(x + w - 10, curr_y, ftype, ha='right', va='center', fontsize=8, fontfamily='monospace', color='#333333')
        curr_y -= gap

# 1. User
user_fields = [
    ("_id", "ObjectId [PK]"),
    ("name", "String"),
    ("email", "String"),
    ("role", "String"),
    ("department", "String"),
    ("status", "String"),
    ("createdAt", "Date"),
    ("updatedAt", "Date")
]
draw_table(ax, 40, 1000, 270, 240, "User", user_fields)

# 2. Complaint
complaint_fields = [
    ("_id", "ObjectId [PK]"),
    ("title", "String"),
    ("description", "String"),
    ("categoryId", "ObjectId [FK]"),
    ("submittedBy", "ObjectId [FK]"),
    ("status", "String"),
    ("priority", "String"),
    ("attachments", "Array"),
    ("createdAt", "Date"),
    ("updatedAt", "Date")
]
draw_table(ax, 400, 1000, 290, 270, "Complaint", complaint_fields)

# 3. Category
category_fields = [
    ("_id", "ObjectId [PK]"),
    ("name", "String"),
    ("description", "String"),
    ("isActive", "Boolean"),
    ("createdAt", "Date"),
    ("updatedAt", "Date")
]
draw_table(ax, 780, 1000, 260, 200, "Category", category_fields)

# 4. AssignmentRule
assign_fields = [
    ("_id", "ObjectId [PK]"),
    ("name", "String"),
    ("criteria", "Object"),
    ("targetRole", "String"),
    ("priority", "Number"),
    ("isActive", "Boolean"),
    ("createdAt", "Date"),
    ("updatedAt", "Date")
]
draw_table(ax, 1140, 1000, 280, 240, "AssignmentRule", assign_fields)

# 5. AssignmentLog
log_fields = [
    ("_id", "ObjectId [PK]"),
    ("complaintId", "ObjectId [FK]"),
    ("staffId", "ObjectId [FK]"),
    ("assignedBy", "ObjectId [FK]"),
    ("assignedAt", "Date"),
    ("status", "String"),
    ("notes", "String"),
    ("updatedAt", "Date")
]
draw_table(ax, 400, 670, 290, 240, "AssignmentLog", log_fields)

# 6. EscalationRule
esc_fields = [
    ("_id", "ObjectId [PK]"),
    ("name", "String"),
    ("conditions", "Object"),
    ("escalateToRule", "String"),
    ("escalationLevel", "Number"),
    ("slaHours", "Number"),
    ("isActive", "Boolean"),
    ("createdAt", "Date"),
    ("updatedAt", "Date")
]
draw_table(ax, 1140, 700, 280, 250, "EscalationRule", esc_fields)

# 7. Payment
pay_fields = [
    ("_id", "ObjectId [PK]"),
    ("complaintId", "ObjectId [FK]"),
    ("amount", "Number"),
    ("currency", "String"),
    ("status", "String"),
    ("paymentMethod", "String"),
    ("transactionRef", "String"),
    ("paidAt", "Date"),
    ("createdAt", "Date"),
    ("updatedAt", "Date")
]
draw_table(ax, 40, 520, 270, 260, "Payment", pay_fields)

# 8. ResponseTemplate
resp_fields = [
    ("_id", "ObjectId [PK]"),
    ("name", "String"),
    ("categoryId", "ObjectId [FK]"),
    ("content", "String"),
    ("variables", "Array"),
    ("isActive", "Boolean"),
    ("createdAt", "Date"),
    ("updatedAt", "Date")
]
draw_table(ax, 350, 370, 260, 230, "ResponseTemplate", resp_fields)

# 9. Notification
notif_fields = [
    ("_id", "ObjectId [PK]"),
    ("userId", "ObjectId [FK]"),
    ("type", "String"),
    ("title", "String"),
    ("message", "String"),
    ("isRead", "Boolean"),
    ("createdAt", "Date")
]
draw_table(ax, 640, 370, 230, 210, "Notification", notif_fields)

# 10. Feedback
fb_fields = [
    ("_id", "ObjectId [PK]"),
    ("complaintId", "ObjectId [FK]"),
    ("rating", "Number"),
    ("comments", "String"),
    ("submittedBy", "ObjectId [FK]"),
    ("createdAt", "Date"),
    ("updatedAt", "Date")
]
draw_table(ax, 900, 370, 250, 220, "Feedback", fb_fields)

# 11. AuditLog
audit_fields = [
    ("_id", "ObjectId [PK]"),
    ("userId", "ObjectId [FK]"),
    ("action", "String"),
    ("entity", "String"),
    ("entityId", "ObjectId"),
    ("details", "Object"),
    ("ipAddress", "String"),
    ("createdAt", "Date")
]
draw_table(ax, 1180, 400, 260, 230, "AuditLog", audit_fields)

# Legend Box
legend = patches.FancyBboxPatch((40, 140), 270, 85, boxstyle="square,pad=0.0",
                                facecolor='#ffffff', edgecolor='#000000', linewidth=1.2, linestyle=':')
ax.add_patch(legend)
ax.text(55, 205, "Legend", fontsize=10, fontweight='bold', color='#000000')
ax.text(55, 180, "_id", fontsize=9, fontweight='bold', color='#000000')
ax.text(125, 180, ": Primary Key [PK]", fontsize=8.5, color='#333333')
ax.text(55, 155, "ObjectId", fontsize=8.5, fontfamily='monospace', color='#000000')
ax.text(125, 155, ": Document Reference [FK]", fontsize=8.5, color='#333333')

# Arrows
def arrow(ax, x1, y1, x2, y2, label=None, lx=None, ly=None):
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6",
                                color="#000000", lw=1.3, shrinkA=2, shrinkB=2))
    if label:
        if lx is None: lx = (x1 + x2) / 2
        if ly is None: ly = (y1 + y2) / 2
        ax.text(lx, ly, label, ha='center', va='center', fontsize=7.5, fontweight='bold',
                color='#000000', bbox=dict(boxstyle='square,pad=0.2', facecolor='#ffffff', edgecolor='#000000', lw=0.7))

# Complaint -> User ("submitted by")
arrow(ax, 400, 930, 310, 930, "submitted by")

# Complaint -> Category ("belongs to")
arrow(ax, 690, 930, 780, 930, "belongs to")

# AssignmentLog -> Complaint ("related to")
arrow(ax, 545, 670, 545, 730, "related to")

# AssignmentLog -> User ("assigned staff (staff)")
ax.plot([400, 350, 350, 310], [550, 550, 850, 850], color='#000000', lw=1.3)
arrow(ax, 350, 850, 310, 850, "assigned staff (staff)", lx=330, ly=700)

# Payment -> User ("sent to")
arrow(ax, 175, 520, 175, 760, "sent to")

# Feedback -> Complaint ("feedback for")
arrow(ax, 1025, 370, 690, 750, "feedback for", lx=860, ly=560)

# AuditLog -> EscalationRule ("performed by")
arrow(ax, 1310, 400, 1310, 450, "performed by")

plt.subplots_adjust(left=0.01, right=0.99, top=0.98, bottom=0.02)
out_path = r"d:\Uzhavan\docs\images\mongodb_database_schema_bw.png"
plt.savefig(out_path, dpi=300, facecolor=fig.get_facecolor(), edgecolor='none', bbox_inches='tight')
print(f"DONE: Generated {out_path}")
