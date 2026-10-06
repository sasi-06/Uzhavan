import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

def render_booking_tracking():
    fig = plt.figure(figsize=(18, 12), dpi=300)
    ax = fig.add_subplot(111)
    ax.set_xlim(0, 1800)
    ax.set_ylim(0, 1200)
    ax.axis('off')

    fig.patch.set_facecolor('#ffffff')
    ax.set_facecolor('#ffffff')

    # Overall Container Border
    border = patches.FancyBboxPatch((40, 40), 1720, 1120, boxstyle="square,pad=0.0",
                                    facecolor='#ffffff', edgecolor='#000000', linewidth=1.5)
    ax.add_patch(border)

    # Document / Screen Title Header
    ax.text(900, 1125, "UZHAVAN: BOOKING LIST & LIFECYCLE TRACKING MODULE",
            ha='center', va='center', fontsize=16, fontweight='bold', color='#000000')
    ax.text(900, 1098, "Figure 6.6 / 6.8 — Mobile Booking List View with Active Status Badges and Lifecycle Detail Timeline Sheet",
            ha='center', va='center', fontsize=11, fontstyle='italic', color='#333333')
    ax.plot([80, 1720], [1075, 1075], color='#000000', lw=1.2)

    # ==========================================
    # LEFT PANEL: MOBILE BOOKING LIST VIEW (Phone Frame)
    # ==========================================
    phone_x, phone_y, phone_w, phone_h = 90, 80, 720, 960
    phone_box = patches.FancyBboxPatch((phone_x, phone_y), phone_w, phone_h,
                                       boxstyle="round,pad=0.0,rounding_size=20",
                                       facecolor='#ffffff', edgecolor='#000000', linewidth=2.0)
    ax.add_patch(phone_box)

    # Phone Top Bar / Status Bar
    ax.text(phone_x + 30, phone_y + phone_h - 25, "09:41 AM", fontsize=9, fontweight='bold', va='center')
    ax.text(phone_x + phone_w - 30, phone_y + phone_h - 25, "4G LTE | 92%", fontsize=9, fontweight='bold', ha='right', va='center')
    ax.plot([phone_x + 10, phone_x + phone_w - 10], [phone_y + phone_h - 40, phone_y + phone_h - 40], color='#cccccc', lw=1.0)

    # App Navigation Bar
    ax.text(phone_x + 30, phone_y + phone_h - 65, "<  My Rental Bookings (Farmer Hub)",
            fontsize=13, fontweight='bold', va='center')
    ax.text(phone_x + phone_w - 30, phone_y + phone_h - 65, "[Filter]", fontsize=10, fontweight='bold', ha='right', va='center')

    # Search Bar
    search_box = patches.FancyBboxPatch((phone_x + 25, phone_y + phone_h - 120), phone_w - 50, 36,
                                        boxstyle="round,pad=0.0,rounding_size=8",
                                        facecolor='#f7f7f7', edgecolor='#000000', linewidth=1.0)
    ax.add_patch(search_box)
    ax.text(phone_x + 45, phone_y + phone_h - 102, "Search by Machine, Driver or Booking ID...",
            fontsize=9.5, fontstyle='italic', color='#555555', va='center')

    # Filter Category Chips
    chips = [("All (4)", True), ("In Progress (1)", False), ("Confirmed (1)", False), ("Completed (2)", False)]
    cx = phone_x + 25
    for label, is_active in chips:
        cw = 150 if len(label) > 10 else 100
        chip_box = patches.FancyBboxPatch((cx, phone_y + phone_h - 165), cw, 28,
                                          boxstyle="round,pad=0.0,rounding_size=14",
                                          facecolor='#000000' if is_active else '#ffffff',
                                          edgecolor='#000000', linewidth=1.2)
        ax.add_patch(chip_box)
        ax.text(cx + cw/2, phone_y + phone_h - 151, label,
                ha='center', va='center', fontsize=9, fontweight='bold',
                color='#ffffff' if is_active else '#000000')
        cx += cw + 12

    # CARD 1: IN PROGRESS BOOKING
    c1_y = phone_y + phone_h - 425
    card1 = patches.FancyBboxPatch((phone_x + 25, c1_y), phone_w - 50, 240,
                                   boxstyle="round,pad=0.0,rounding_size=12",
                                   facecolor='#ffffff', edgecolor='#000000', linewidth=1.5)
    ax.add_patch(card1)

    # Badge: IN PROGRESS
    b1 = patches.FancyBboxPatch((phone_x + phone_w - 180, c1_y + 195), 140, 28,
                                boxstyle="round,pad=0.0,rounding_size=6",
                                facecolor='#000000', edgecolor='#000000', linewidth=1.0)
    ax.add_patch(b1)
    ax.text(phone_x + phone_w - 110, c1_y + 209, "[IN PROGRESS]",
            ha='center', va='center', fontsize=8.5, fontweight='bold', color='#ffffff')

    ax.text(phone_x + 45, c1_y + 210, "BK-20261014-0042", fontsize=10, fontweight='bold', color='#000000')
    ax.text(phone_x + 45, c1_y + 185, "Mahindra 575 DI Sarpanch (45 HP)", fontsize=12, fontweight='bold')
    ax.text(phone_x + 45, c1_y + 165, "Implement: 9-Tyne Cultivator | Land Area: 3.0 Acres", fontsize=9.5, color='#333333')
    ax.text(phone_x + 45, c1_y + 145, "Operator: Muthu K (+91 94421 87654)", fontsize=9.5, color='#333333')
    ax.text(phone_x + 45, c1_y + 125, "Field: East Block, K.R. Nagar (Kovilpatti)", fontsize=9.5, color='#333333')

    # Live Dispatch Timer Box
    t_box = patches.FancyBboxPatch((phone_x + 45, c1_y + 60), phone_w - 90, 48,
                                   boxstyle="round,pad=0.0,rounding_size=6",
                                   facecolor='#f0f0f0', edgecolor='#000000', linewidth=1.0, linestyle='--')
    ax.add_patch(t_box)
    ax.text(phone_x + 60, c1_y + 90, "Live Field Work Timer: 02h 15m elapsed", fontsize=9.5, fontweight='bold')
    ax.text(phone_x + 60, c1_y + 72, "Fuel Monitored: 18.2 L | Total Est: INR 4,200 (COD)", fontsize=8.5, color='#444444')

    # Action Buttons for Card 1
    btn_view = patches.FancyBboxPatch((phone_x + 45, c1_y + 15), 380, 34,
                                      boxstyle="round,pad=0.0,rounding_size=6",
                                      facecolor='#000000', edgecolor='#000000', linewidth=1.2)
    ax.add_patch(btn_view)
    ax.text(phone_x + 235, c1_y + 32, "View Live Lifecycle Tracking ->",
            ha='center', va='center', fontsize=9.5, fontweight='bold', color='#ffffff')

    btn_call = patches.FancyBboxPatch((phone_x + 440, c1_y + 15), phone_w - 485, 34,
                                      boxstyle="round,pad=0.0,rounding_size=6",
                                      facecolor='#ffffff', edgecolor='#000000', linewidth=1.2)
    ax.add_patch(btn_call)
    ax.text(phone_x + 440 + (phone_w - 485)/2, c1_y + 32, "[Call Driver]",
            ha='center', va='center', fontsize=9.5, fontweight='bold', color='#000000')

    # CARD 2: CONFIRMED UPCOMING BOOKING
    c2_y = phone_y + phone_h - 665
    card2 = patches.FancyBboxPatch((phone_x + 25, c2_y), phone_w - 50, 220,
                                   boxstyle="round,pad=0.0,rounding_size=12",
                                   facecolor='#ffffff', edgecolor='#000000', linewidth=1.5)
    ax.add_patch(card2)

    # Badge: CONFIRMED
    b2 = patches.FancyBboxPatch((phone_x + phone_w - 180, c2_y + 175), 140, 28,
                                boxstyle="round,pad=0.0,rounding_size=6",
                                facecolor='#ffffff', edgecolor='#000000', linewidth=1.5)
    ax.add_patch(b2)
    ax.text(phone_x + phone_w - 110, c2_y + 189, "[CONFIRMED]",
            ha='center', va='center', fontsize=8.5, fontweight='bold', color='#000000')

    ax.text(phone_x + 45, c2_y + 190, "BK-20261016-0051", fontsize=10, fontweight='bold', color='#000000')
    ax.text(phone_x + 45, c2_y + 165, "John Deere 5050D + Paddy Harvester", fontsize=12, fontweight='bold')
    ax.text(phone_x + 45, c2_y + 145, "Slot: Oct 16, 2026 (Morning Shift: 06:00 AM - 12:00 PM)", fontsize=9.5, color='#333333')
    ax.text(phone_x + 45, c2_y + 125, "Owner: Selvam R | Agreed Acre Rate: INR 1,650 / acre", fontsize=9.5, color='#333333')
    ax.text(phone_x + 45, c2_y + 105, "Weather Advisory: Clear Sky (0% Rain Hazard Alert)", fontsize=9, color='#222222')

    # Action Buttons for Card 2
    btn_det = patches.FancyBboxPatch((phone_x + 45, c2_y + 20), 400, 34,
                                     boxstyle="round,pad=0.0,rounding_size=6",
                                     facecolor='#000000', edgecolor='#000000', linewidth=1.2)
    ax.add_patch(btn_det)
    ax.text(phone_x + 245, c2_y + 37, "View Scheduled Slot Dossier",
            ha='center', va='center', fontsize=9.5, fontweight='bold', color='#ffffff')

    btn_cancel = patches.FancyBboxPatch((phone_x + 460, c2_y + 20), phone_w - 505, 34,
                                        boxstyle="round,pad=0.0,rounding_size=6",
                                        facecolor='#ffffff', edgecolor='#000000', linewidth=1.2)
    ax.add_patch(btn_cancel)
    ax.text(phone_x + 460 + (phone_w - 505)/2, c2_y + 37, "Cancel Slot",
            ha='center', va='center', fontsize=9.5, fontweight='bold', color='#000000')

    # CARD 3: COMPLETED BOOKING (Snippet)
    c3_y = phone_y + phone_h - 890
    card3 = patches.FancyBboxPatch((phone_x + 25, c3_y), phone_w - 50, 205,
                                   boxstyle="round,pad=0.0,rounding_size=12",
                                   facecolor='#fafafa', edgecolor='#888888', linewidth=1.2)
    ax.add_patch(card3)

    # Badge: COMPLETED
    b3 = patches.FancyBboxPatch((phone_x + phone_w - 180, c3_y + 160), 140, 28,
                                boxstyle="round,pad=0.0,rounding_size=6",
                                facecolor='#e0e0e0', edgecolor='#000000', linewidth=1.0)
    ax.add_patch(b3)
    ax.text(phone_x + phone_w - 110, c3_y + 174, "[COMPLETED]",
            ha='center', va='center', fontsize=8.5, fontweight='bold', color='#000000')

    ax.text(phone_x + 45, c3_y + 175, "BK-20261011-0038", fontsize=10, fontweight='bold', color='#555555')
    ax.text(phone_x + 45, c3_y + 150, "Sonalika DI 60 + Rotary Tiller", fontsize=12, fontweight='bold')
    ax.text(phone_x + 45, c3_y + 130, "Completed: Oct 11, 2026 | 2.0 Acres Tilled", fontsize=9.5, color='#444444')
    ax.text(phone_x + 45, c3_y + 110, "Diesel Audit: FAIR (+1.2% variance) | Paid: INR 2,800", fontsize=9, color='#222222')

    btn_rcpt = patches.FancyBboxPatch((phone_x + 45, c3_y + 20), phone_w - 90, 34,
                                      boxstyle="round,pad=0.0,rounding_size=6",
                                      facecolor='#ffffff', edgecolor='#000000', linewidth=1.2)
    ax.add_patch(btn_rcpt)
    ax.text(phone_x + phone_w/2, c3_y + 37, "[Download Verified Digital Receipt & Rating Dossier]",
            ha='center', va='center', fontsize=9.5, fontweight='bold', color='#000000')

    # Phone Bottom App Navigation
    nav_h = 50
    nav_box = patches.FancyBboxPatch((phone_x + 10, phone_y + 10), phone_w - 20, nav_h,
                                     boxstyle="round,pad=0.0,rounding_size=10",
                                     facecolor='#f7f7f7', edgecolor='#000000', linewidth=1.0)
    ax.add_patch(nav_box)
    nav_items = [("Home", "Catalog"), ("Machines", "Nearby"), ("Bookings", "Orders (1)"), ("Profile", "Settings")]
    for idx, (title, sub) in enumerate(nav_items):
        nx = phone_x + 40 + idx * 170
        is_sel = (idx == 2)
        ax.text(nx + 40, phone_y + 38, f"[{title}]", fontsize=9.5, ha='center', va='center',
                fontweight='bold' if is_sel else 'normal', color='#000000' if is_sel else '#555555')
        ax.text(nx + 40, phone_y + 22, sub, fontsize=8, ha='center', va='center',
                fontweight='bold' if is_sel else 'normal', color='#000000' if is_sel else '#777777')

    # ==========================================
    # RIGHT PANEL: LIFECYCLE TIMELINE & DETAIL MODAL
    # ==========================================
    modal_x, modal_y, modal_w, modal_h = 870, 80, 840, 960
    modal_box = patches.FancyBboxPatch((modal_x, modal_y), modal_w, modal_h,
                                       boxstyle="round,pad=0.0,rounding_size=16",
                                       facecolor='#ffffff', edgecolor='#000000', linewidth=2.0)
    ax.add_patch(modal_box)

    # Modal Header
    ax.text(modal_x + 35, modal_y + modal_h - 40, "Booking Lifecycle & Audit Timeline",
            fontsize=14, fontweight='bold', color='#000000')
    ax.text(modal_x + 35, modal_y + modal_h - 65, "Detailed Stage Transition, SLA Verification & Diesel Benchmark",
            fontsize=10, fontstyle='italic', color='#555555')
    ax.text(modal_x + modal_w - 35, modal_y + modal_h - 40, "✕ Close",
            fontsize=11, fontweight='bold', ha='right', color='#000000')
    ax.plot([modal_x + 20, modal_x + modal_w - 20], [modal_y + modal_h - 85, modal_y + modal_h - 85],
            color='#000000', lw=1.2)

    # Summary Specs Table Box
    sum_box = patches.FancyBboxPatch((modal_x + 35, modal_y + modal_h - 225), modal_w - 70, 125,
                                     boxstyle="round,pad=0.0,rounding_size=8",
                                     facecolor='#f7f7f7', edgecolor='#000000', linewidth=1.2)
    ax.add_patch(sum_box)

    ax.text(modal_x + 55, modal_y + modal_h - 110, "Booking Reference: BK-20261014-0042", fontsize=11, fontweight='bold')
    ax.text(modal_x + 55, modal_y + modal_h - 132, "Machinery: Mahindra 575 DI (45 HP) | Rotavator", fontsize=9.5)
    ax.text(modal_x + 55, modal_y + modal_h - 152, "Farmer: Murugan K (+91 98765 43210) | Kovilpatti", fontsize=9.5)
    ax.text(modal_x + 55, modal_y + modal_h - 172, "Operator: Muthu K (+91 94421 87654) | Assigned Driver", fontsize=9.5)
    ax.text(modal_x + 55, modal_y + modal_h - 192, "Payment Mode: Cash on Delivery (COD) | Agreed Rate: ₹1,400 / acre", fontsize=9.5)
    ax.text(modal_x + 55, modal_y + modal_h - 212, "Scheduled Shift: Morning (06:00 AM - 12:00 PM) | Total Area: 3.0 Acres", fontsize=9.5)

    # TIMELINE STEPPER
    ax.text(modal_x + 35, modal_y + modal_h - 250, "CHRONOLOGICAL LIFECYCLE AUDIT TRAIL:",
            fontsize=11, fontweight='bold', color='#000000')

    timeline_steps = [
        ("1. REQUEST SUBMITTED", "Oct 14, 2026 - 08:30 AM",
         "Farmer placed booking via Mobile App / Voice Interface.\nInitial slot reservation locked in Firestore.",
         "COMPLETED", True),
        ("2. OWNER ACCEPTED & DISPATCHED", "Oct 14, 2026 - 09:15 AM",
         "Owner Selvam R confirmed reservation. Driver Muthu assigned.\nSMS dispatch alert sent to farmer.",
         "COMPLETED", True),
        ("3. WORK IN PROGRESS (ON FIELD)", "Oct 15, 2026 - 06:30 AM",
         "Driver arrived on field. Plowing started with GPS timer.\nCurrent Duration: 02h 15m | Area covered: 2.2 / 3.0 Acres.",
         "ACTIVE", True),
        ("4. DIESEL CONSUMPTION AUDIT", "Pending Field Completion",
         "Scientific Baseline: 25.5 L based on 45 HP & clay soil resistance.\nOperator Billed: 26.0 L (Variance: +1.96% - FAIR BADGE).",
         "UPCOMING", False),
        ("5. PAYMENT & FEEDBACK SETTLEMENT", "Pending Work Completion",
         "Farmer settles ₹4,200 via COD/UPI. Digital receipt issued.\nMutual rating submitted to update operator reputation.",
         "UPCOMING", False)
    ]

    ty = modal_y + modal_h - 290
    step_gap = 115

    for idx, (title, time_str, desc, status_type, is_done) in enumerate(timeline_steps):
        # Stepper Circle & Line
        circle_color = '#000000' if is_done else '#ffffff'
        circle_edge = '#000000'
        step_circ = patches.Circle((modal_x + 60, ty - 10), 16,
                                   facecolor=circle_color, edgecolor=circle_edge, lw=2.0)
        ax.add_patch(step_circ)

        step_num = str(idx + 1)
        ax.text(modal_x + 60, ty - 10, step_num if not is_done else "✓",
                ha='center', va='center', fontsize=9.5, fontweight='bold',
                color='#ffffff' if is_done else '#000000')

        # Vertical line connecting steps
        if idx < len(timeline_steps) - 1:
            ax.plot([modal_x + 60, modal_x + 60], [ty - 26, ty - step_gap + 6],
                    color='#000000' if is_done else '#aaaaaa', lw=2.0,
                    linestyle='-' if is_done else ':')

        # Step Content Box
        step_box = patches.FancyBboxPatch((modal_x + 95, ty - 50), modal_w - 145, 75,
                                          boxstyle="round,pad=0.0,rounding_size=6",
                                          facecolor='#f7f7f7' if status_type == 'ACTIVE' else '#ffffff',
                                          edgecolor='#000000' if status_type == 'ACTIVE' else '#cccccc',
                                          linewidth=1.5 if status_type == 'ACTIVE' else 1.0)
        ax.add_patch(step_box)

        ax.text(modal_x + 110, ty - 5, title, fontsize=10.5, fontweight='bold', color='#000000')
        ax.text(modal_x + modal_w - 70, ty - 5, time_str, fontsize=8.5, ha='right', color='#555555')

        # Status badge on right
        desc_lines = desc.split('\n')
        ax.text(modal_x + 110, ty - 22, desc_lines[0], fontsize=8.8, color='#222222')
        if len(desc_lines) > 1:
            ax.text(modal_x + 110, ty - 38, desc_lines[1], fontsize=8.5, color='#555555')

        ty -= step_gap

    # Bottom Modal Action Controls
    bot_y = modal_y + 35
    b_act1 = patches.FancyBboxPatch((modal_x + 35, bot_y), 360, 42,
                                    boxstyle="round,pad=0.0,rounding_size=8",
                                    facecolor='#000000', edgecolor='#000000', linewidth=1.2)
    ax.add_patch(b_act1)
    ax.text(modal_x + 215, bot_y + 21, "Download Official Audit Receipt (PDF)",
            ha='center', va='center', fontsize=10, fontweight='bold', color='#ffffff')

    b_act2 = patches.FancyBboxPatch((modal_x + 420, bot_y), 220, 42,
                                    boxstyle="round,pad=0.0,rounding_size=8",
                                    facecolor='#ffffff', edgecolor='#000000', linewidth=1.2)
    ax.add_patch(b_act2)
    ax.text(modal_x + 530, bot_y + 21, "Report Field Delay",
            ha='center', va='center', fontsize=10, fontweight='bold', color='#000000')

    b_act3 = patches.FancyBboxPatch((modal_x + 660, bot_y), modal_w - 695, 42,
                                    boxstyle="round,pad=0.0,rounding_size=8",
                                    facecolor='#ffffff', edgecolor='#000000', linewidth=1.2)
    ax.add_patch(b_act3)
    ax.text(modal_x + 660 + (modal_w - 695)/2, bot_y + 21, "Cancel Booking",
            ha='center', va='center', fontsize=10, fontweight='bold', color='#000000')

    # Save to file
    out_path = r"d:\Uzhavan\docs\images\booking_list_and_tracking_bw.png"
    plt.savefig(out_path, dpi=300, facecolor=fig.get_facecolor(), bbox_inches='tight')
    plt.close()
    print(f"Successfully generated {out_path}")

if __name__ == '__main__':
    render_booking_tracking()
