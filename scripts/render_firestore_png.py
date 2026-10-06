import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

fig = plt.figure(figsize=(19, 13), dpi=300)
ax = fig.add_subplot(111)
ax.set_xlim(0, 1900)
ax.set_ylim(0, 1300)
ax.axis('off')

fig.patch.set_facecolor('#ffffff')
ax.set_facecolor('#ffffff')

# Document Header
ax.text(950, 1260, "Google Cloud Firestore Database Schema – Uzhavan Agro-Machine Rental Marketplace",
        ha='center', va='center', fontsize=17, fontweight='bold', color='#000000')
ax.plot([250, 1650], [1235, 1235], color='#000000', lw=1.2, linestyle='--')
ax.text(950, 1215, "Fig 4.2: Firestore Collections, Document Schemas, Subcollections and Entity Relationships",
        ha='center', va='center', fontsize=11, fontstyle='italic', color='#222222')

def draw_table(ax, x, y, w, h, title, sub_title, fields, is_sub=False):
    # Outer box
    box = patches.FancyBboxPatch((x, y - h), w, h, boxstyle="square,pad=0.0",
                                 facecolor='#ffffff', edgecolor='#000000', linewidth=1.6)
    ax.add_patch(box)
    
    # Header bar
    header_h = 38
    h_bg = '#f2f2f2' if not is_sub else '#e5e5e5'
    header_box = patches.FancyBboxPatch((x, y - header_h), w, header_h, boxstyle="square,pad=0.0",
                                        facecolor=h_bg, edgecolor='#000000', linewidth=1.6)
    ax.add_patch(header_box)
    
    # Header text
    ax.text(x + w/2, y - 13, title, ha='center', va='center', fontsize=11, fontweight='bold', color='#000000')
    ax.text(x + w/2, y - 27, sub_title, ha='center', va='center', fontsize=8.5, fontfamily='monospace', color='#333333')
    
    # Field rows
    curr_y = y - 52
    gap = (h - 52) / max(len(fields), 1)
    for name, ftype in fields:
        is_pk = "[PK]" in ftype
        is_fk = "[FK" in ftype
        fw = 'bold' if (is_pk or is_fk) else 'normal'
        ax.text(x + 12, curr_y, name, ha='left', va='center', fontsize=8.8, fontweight=fw, color='#000000')
        ax.text(x + w - 12, curr_y, ftype, ha='right', va='center', fontsize=8.2, fontfamily='monospace', color='#333333')
        curr_y -= gap

# ==================== ENTITY TABLES ====================
# TOP ROW: Y = 1130

# 1. users
users = [
    ("id", "string [PK]"),
    ("phone", "string (E.164)"),
    ("name", "string"),
    ("role", "enum (farmer|owner|agent)"),
    ("village", "string"),
    ("district", "string"),
    ("preferredLang", "string ('ta'|'en')"),
    ("location", "geopoint (lat, lng)"),
    ("rating", "number (4.9)"),
    ("totalHires", "number"),
    ("createdAt", "timestamp")
]
draw_table(ax, 50, 1130, 290, 270, "users", "Document: {userId}", users)

# 2. bookings (Central Entity)
bookings = [
    ("id", "string [PK]"),
    ("farmerId", "string [FK -> users]"),
    ("ownerId", "string [FK -> users]"),
    ("machineId", "string [FK -> machines]"),
    ("status", "enum (pending|confirmed..)"),
    ("bookingDate", "string ('YYYY-MM-DD')"),
    ("timeSlot", "string ('06:00-12:00')"),
    ("acreage", "number (3.0 acres)"),
    ("operationType", "string ('rotavator')"),
    ("totalAmount", "number (₹4200)"),
    ("paymentStatus", "enum (cod|paid_online)"),
    ("isAgentBooking", "boolean"),
    ("dieselAudit", "map {expected, actual..}"),
    ("createdAt", "timestamp")
]
draw_table(ax, 450, 1130, 340, 340, "bookings", "Document: {bookingId}", bookings)

# 3. machines (Asset Catalog)
machines = [
    ("id", "string [PK]"),
    ("ownerId", "string [FK -> users]"),
    ("ownerName", "string"),
    ("type", "enum (tractor|harvester)"),
    ("modelName", "string ('Mahindra 575')"),
    ("horsePower", "number (45 HP)"),
    ("hourlyRate", "number (₹900)"),
    ("acreRate", "number (₹1400)"),
    ("location", "geopoint (lat, lng)"),
    ("geohash", "string ('t9y3q8b')"),
    ("isAvailable", "boolean"),
    ("photoUrls", "array<string>"),
    ("createdAt", "timestamp")
]
draw_table(ax, 900, 1130, 310, 320, "machines", "Document: {machineId}", machines)

# 4. smartDieselAudit
diesel = [
    ("id", "string [PK]"),
    ("bookingId", "string [FK -> bookings]"),
    ("horsePower", "number (HP)"),
    ("soilFactor", "number (resistance)"),
    ("acreage", "number (acres)"),
    ("expectedLiters", "number (baseline)"),
    ("actualLiters", "number (billed)"),
    ("variancePct", "number (+/- %)"),
    ("auditVerdict", "enum (normal|excessive)"),
    ("timestamp", "timestamp")
]
draw_table(ax, 1310, 1130, 300, 270, "dieselAudits", "Document: {auditId}", diesel)

# 5. bookedSlots (Subcollection under machines)
# machines bottom is 1130 - 320 = 810. bookedSlots top at 740
slots = [
    ("slotId", "string [PK]"),
    ("bookingId", "string [FK -> bookings]"),
    ("date", "string ('YYYY-MM-DD')"),
    ("timeSlot", "string ('06:00-12:00')"),
    ("status", "enum (locked|reserved)"),
    ("lockedAt", "timestamp")
]
draw_table(ax, 900, 740, 310, 190, "bookedSlots", "Subcollection of [machines]", slots, is_sub=True)

# 6. weatherAlerts
weather = [
    ("id", "string [PK]"),
    ("machineId", "string [FK -> machines]"),
    ("bookingId", "string [FK -> bookings]"),
    ("precipProbability", "number (%)"),
    ("forecastRainMm", "number (mm)"),
    ("hazardFlag", "boolean"),
    ("advisoryText", "string"),
    ("timestamp", "timestamp")
]
draw_table(ax, 1310, 800, 300, 220, "weatherAlerts", "Document: {alertId}", weather)

# 7. payments
payments = [
    ("id", "string [PK]"),
    ("bookingId", "string [FK -> bookings]"),
    ("farmerId", "string [FK -> users]"),
    ("amount", "number (₹4200)"),
    ("paymentMethod", "enum (cod|upi_qr)"),
    ("transactionRef", "string (UPI-Ref)"),
    ("escrowStatus", "enum (held|released)"),
    ("paidAt", "timestamp")
]
draw_table(ax, 50, 780, 290, 230, "payments", "Document: {paymentId}", payments)

# 8. onDeviceVoiceLogs
voice = [
    ("id", "string [PK]"),
    ("farmerId", "string [FK -> users]"),
    ("rawTamilText", "string"),
    ("extractedAgrotags", "array<string>"),
    ("parsedAcreage", "number"),
    ("parsedMachine", "string"),
    ("confidence", "number (0-1.0)"),
    ("timestamp", "timestamp")
]
draw_table(ax, 50, 480, 290, 220, "voiceLogs", "Document: {queryId}", voice)

# 9. notifications
notifications = [
    ("id", "string [PK]"),
    ("recipientId", "string [FK -> users]"),
    ("eventType", "string ('slot_booked')"),
    ("title", "string"),
    ("message", "string (Tamil/English)"),
    ("isRead", "boolean"),
    ("createdAt", "timestamp")
]
draw_table(ax, 450, 480, 340, 200, "notifications", "Document: {notifId}", notifications)

# 10. reviews (Feedback)
reviews = [
    ("id", "string [PK]"),
    ("bookingId", "string [FK -> bookings]"),
    ("farmerId", "string [FK -> users]"),
    ("machineId", "string [FK -> machines]"),
    ("machineRating", "number (1-5 stars)"),
    ("dieselSatisfaction", "number (1-5)"),
    ("comments", "string"),
    ("createdAt", "timestamp")
]
draw_table(ax, 900, 480, 310, 220, "reviews", "Document: {reviewId}", reviews)

# 11. auditLogs
audit = [
    ("id", "string [PK]"),
    ("actorId", "string [FK -> users]"),
    ("action", "string ('SLOT_LOCK')"),
    ("entity", "string ('bookings')"),
    ("entityId", "string"),
    ("ipAddress", "string"),
    ("timestamp", "timestamp")
]
draw_table(ax, 1310, 510, 300, 200, "auditLogs", "Document: {logId}", audit)

# 12. Legend Box
legend = patches.FancyBboxPatch((50, 160), 290, 85, boxstyle="square,pad=0.0",
                                facecolor='#ffffff', edgecolor='#000000', linewidth=1.2, linestyle=':')
ax.add_patch(legend)
ax.text(65, 225, "Legend / Firestore Standard", fontsize=9.5, fontweight='bold', color='#000000')
ax.text(65, 202, "[collection]", fontsize=8.5, fontweight='bold', color='#000000')
ax.text(155, 202, ": Top-Level Collection", fontsize=8.2, color='#333333')
ax.text(65, 182, "{docId}", fontsize=8.5, fontfamily='monospace', color='#000000')
ax.text(155, 182, ": Document Unique UID", fontsize=8.2, color='#333333')
ax.text(65, 162, "[PK] / [FK]", fontsize=8.5, fontweight='bold', color='#000000')
ax.text(155, 162, ": Primary Key / Document Ref", fontsize=8.2, color='#333333')

# ==================== CLEAN ORTHOGONAL ARROWS ====================

def draw_pill_label(ax, x, y, text):
    ax.text(x, y, text, ha='center', va='center', fontsize=8, fontweight='bold',
            color='#000000', bbox=dict(boxstyle='square,pad=0.25', facecolor='#ffffff', edgecolor='#000000', lw=0.8))

# 1. bookings -> users ("reserved by farmer")
ax.annotate('', xy=(340, 1040), xytext=(450, 1040),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.4))
draw_pill_label(ax, 395, 1055, "reserved by")

# 2. machines -> users ("owned by owner") [routed above tables with plenty of clearance]
ax.plot([1055, 1055, 195, 195], [1130, 1175, 1175, 1130], color='#000000', lw=1.3)
ax.annotate('', xy=(195, 1130), xytext=(195, 1145),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.3))
draw_pill_label(ax, 625, 1175, "owned by (ownerId)")

# 3. bookings -> machines ("hires machine")
ax.annotate('', xy=(900, 1040), xytext=(790, 1040),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.4))
draw_pill_label(ax, 845, 1055, "hires")

# 4. machines -> bookedSlots ("has subcollection")
ax.annotate('', xy=(1055, 740), xytext=(1055, 810),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.4))
draw_pill_label(ax, 1055, 775, "has subcollection")

# 5. bookedSlots -> bookings ("atomic slot lock")
ax.plot([900, 835, 835, 790], [640, 640, 940, 940], color='#000000', lw=1.3)
ax.annotate('', xy=(790, 940), xytext=(815, 940),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.3))
draw_pill_label(ax, 835, 720, "atomic slot lock")

# 6. payments -> users ("paid by farmer")
ax.annotate('', xy=(195, 860), xytext=(195, 780),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.4))
draw_pill_label(ax, 195, 820, "paid by (farmerId)")

# 7. payments -> bookings ("settlement")
ax.plot([340, 395, 395, 450], [680, 680, 890, 890], color='#000000', lw=1.3)
ax.annotate('', xy=(450, 890), xytext=(420, 890),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.3))
draw_pill_label(ax, 395, 790, "settles")

# 8. reviews -> bookings ("feedback for")
ax.plot([900, 850, 850, 790], [380, 380, 860, 860], color='#000000', lw=1.3)
ax.annotate('', xy=(790, 860), xytext=(815, 860),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.3))
draw_pill_label(ax, 850, 520, "feedback for")

# 9. dieselAudits -> bookings ("verifies fuel")
ax.plot([1310, 1260, 1260, 700, 700], [1000, 1000, 1160, 1160, 1130], color='#000000', lw=1.3)
ax.annotate('', xy=(700, 1130), xytext=(700, 1145),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.3))
draw_pill_label(ax, 980, 1160, "verifies fuel for")

# 10. weatherAlerts -> bookings ("weather alert")
ax.plot([1310, 1240, 1240, 790], [690, 690, 830, 830], color='#000000', lw=1.3)
ax.annotate('', xy=(790, 830), xytext=(815, 830),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.3))
draw_pill_label(ax, 1240, 715, "rain advisory")

# 11. notifications -> users ("alert to")
ax.plot([450, 395, 395, 340], [400, 400, 580, 580], color='#000000', lw=1.3)
ax.annotate('', xy=(340, 580), xytext=(365, 580),
            arrowprops=dict(arrowstyle="->,head_width=0.35,head_length=0.6", color="#000000", lw=1.3))
draw_pill_label(ax, 395, 490, "notifies")

# 12. auditLogs -> bookings/users ("performed by")
ax.plot([1310, 1260, 1260, 1260], [410, 410, 480, 480], color='#000000', lw=1.3)
draw_pill_label(ax, 1260, 445, "logs actor")

# Caption at Bottom
ax.text(950, 80, "Fig 4.2: Google Cloud Firestore Database Schema & Collection Relationships – Uzhavan",
        ha='center', va='center', fontsize=13, fontweight='bold', fontstyle='italic', color='#000000')

plt.subplots_adjust(left=0.01, right=0.99, top=0.98, bottom=0.02)
out_png = r"d:\Uzhavan\docs\images\firestore_database_schema_bw.png"
plt.savefig(out_png, dpi=300, facecolor=fig.get_facecolor(), edgecolor='none', bbox_inches='tight')
print(f"SUCCESS: Generated {out_png}")
