import os
import re
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, Preformatted
)
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            if self._pageNumber > 0:
                self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        # We don't draw running header on cover (page 1)
        if self._pageNumber > 1:
            self.saveState()
            self.setFont("Times-Roman", 8.5)
            self.setFillColor(colors.HexColor("#555555"))
            # Header
            self.drawString(55, 800, "UZHAVAN: AI-POWERED AGRO-MACHINE RENTAL MARKETPLACE")
            self.setStrokeColor(colors.HexColor("#bbbbbb"))
            self.setLineWidth(0.5)
            self.line(55, 792, 540, 792)
            # Footer
            self.line(55, 45, 540, 45)
            self.drawCentredString(297, 32, f"{self._pageNumber - 1}")
            self.restoreState()

def build_pdf():
    md_path = os.path.join(os.path.dirname(__file__), "..", "docs", "PROJECT_REPORT.md")
    pdf_path = os.path.join(os.path.dirname(__file__), "..", "docs", "PROJECT_REPORT.pdf")
    pdf_path = os.path.abspath(pdf_path)

    with open(md_path, "r", encoding="utf-8") as f:
        md_text = f.read()

    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=A4,
        leftMargin=55,
        rightMargin=55,
        topMargin=55,
        bottomMargin=55
    )

    styles = getSampleStyleSheet()

    h1_style = ParagraphStyle(
        'RepH1',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=13.5,
        leading=17,
        alignment=1, # Center
        spaceBefore=12,
        spaceAfter=10,
        keepWithNext=True
    )

    h2_style = ParagraphStyle(
        'RepH2',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=11.5,
        leading=15,
        spaceBefore=10,
        spaceAfter=6,
        keepWithNext=True
    )

    h3_style = ParagraphStyle(
        'RepH3',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=10.5,
        leading=14,
        spaceBefore=8,
        spaceAfter=4,
        keepWithNext=True
    )

    body_style = ParagraphStyle(
        'RepBody',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=9.5,
        leading=13.5,
        alignment=4, # Justified
        spaceAfter=6,
        firstLineIndent=16
    )

    bullet_style = ParagraphStyle(
        'RepBullet',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=9,
        leading=13,
        leftIndent=15,
        spaceAfter=3
    )

    code_style = ParagraphStyle(
        'RepCode',
        parent=styles['Normal'],
        fontName='Courier',
        fontSize=7.5,
        leading=10,
        textColor=colors.HexColor("#222222")
    )

    table_header = ParagraphStyle(
        'RepTH',
        parent=styles['Normal'],
        fontName='Times-Bold',
        fontSize=8.5,
        leading=11,
        alignment=1,
        textColor=colors.white
    )

    table_cell = ParagraphStyle(
        'RepTD',
        parent=styles['Normal'],
        fontName='Times-Roman',
        fontSize=8,
        leading=10.5
    )

    caption_style = ParagraphStyle(
        'RepCap',
        parent=styles['Normal'],
        fontName='Times-Italic',
        fontSize=8.5,
        leading=11,
        alignment=1,
        spaceAfter=10
    )

    def format_inline(txt):
        txt = txt.replace("&", "&amp;")
        txt = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', txt)
        txt = re.sub(r'\*(.+?)\*', r'<i>\1</i>', txt)
        txt = re.sub(r'`([^`]+)`', r'<font face="Courier">\1</font>', txt)
        txt = txt.replace("<br>", "<br/>")
        return txt

    story = []
    lines = md_text.split("\n")

    in_code = False
    code_lines = []
    in_table = False
    table_lines = []

    def flush_table(rows):
        if not rows:
            return None
        parsed_rows = []
        is_first = True
        num_cols = 0
        for r in rows:
            r = r.strip()
            if not r or r.startswith("| ---") or r.startswith("|:---") or r.startswith("| :---"):
                continue
            cols = [c.strip() for c in r.split("|")[1:-1]]
            if not cols:
                continue
            num_cols = max(num_cols, len(cols))
            row_items = []
            for c in cols:
                c_formatted = format_inline(c)
                if is_first:
                    row_items.append(Paragraph(f"<b>{c_formatted}</b>", table_header))
                else:
                    row_items.append(Paragraph(c_formatted, table_cell))
            parsed_rows.append(row_items)
            is_first = False

        if not parsed_rows:
            return None

        # Width calculation
        total_width = 485
        col_w = total_width / num_cols
        t = Table(parsed_rows, colWidths=[col_w]*num_cols)
        t.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor("#1b5e20")),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#555555")),
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('TOPPADDING', (0,0), (-1,-1), 3),
            ('BOTTOMPADDING', (0,0), (-1,-1), 3),
            ('LEFTPADDING', (0,0), (-1,-1), 4),
            ('RIGHTPADDING', (0,0), (-1,-1), 4),
        ]))
        return t

    i = 0
    while i < len(lines):
        line = lines[i]

        if line.strip().startswith("```"):
            if in_code:
                code_text = "\n".join(code_lines)
                # Cap lines to avoid overflow
                sub_lines = code_text.split("\n")[:40]
                story.append(Preformatted("\n".join(sub_lines), code_style))
                story.append(Spacer(1, 4))
                in_code = False
                code_lines = []
            else:
                in_code = True
                code_lines = []
            i += 1
            continue

        if in_code:
            code_lines.append(line[:100])
            i += 1
            continue

        if line.strip().startswith("|"):
            if not in_table:
                in_table = True
                table_lines = []
            table_lines.append(line)
            i += 1
            continue
        else:
            if in_table:
                tbl = flush_table(table_lines)
                if tbl:
                    story.append(tbl)
                    story.append(Spacer(1, 6))
                in_table = False
                table_lines = []

        if "<div style=\"page-break-after: always;\"></div>" in line:
            story.append(PageBreak())
            i += 1
            continue

        stripped = line.strip()

        if stripped.startswith("# "):
            story.append(Paragraph(format_inline(stripped[2:]), h1_style))
        elif stripped.startswith("## "):
            story.append(Paragraph(format_inline(stripped[3:]), h2_style))
        elif stripped.startswith("### "):
            story.append(Paragraph(format_inline(stripped[4:]), h3_style))
        elif stripped.startswith("#### "):
            story.append(Paragraph(format_inline(stripped[5:]), h3_style))
        elif stripped.startswith("- ") or stripped.startswith("• "):
            story.append(Paragraph(f"• {format_inline(stripped[2:])}", bullet_style))
        elif re.match(r'^\d+\.\s', stripped):
            story.append(Paragraph(format_inline(stripped), bullet_style))
        elif stripped.startswith("*Fig"):
            story.append(Paragraph(format_inline(stripped), caption_style))
        elif stripped == "---":
            story.append(Spacer(1, 6))
        elif stripped == "":
            pass
        else:
            story.append(Paragraph(format_inline(stripped), body_style))

        i += 1

    if in_table:
        tbl = flush_table(table_lines)
        if tbl:
            story.append(tbl)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Full Project Report PDF built: {pdf_path}")

if __name__ == '__main__':
    build_pdf()
