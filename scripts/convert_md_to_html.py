import os
import re

def convert():
    md_path = os.path.join(os.path.dirname(__file__), "..", "docs", "PROJECT_REPORT.md")
    html_path = os.path.join(os.path.dirname(__file__), "..", "docs", "PROJECT_REPORT.html")

    with open(md_path, "r", encoding="utf-8") as f:
        md = f.read()

    css = """
<style>
  @page {
    size: A4;
    margin: 25mm 20mm 25mm 25mm;
  }
  @media print {
    body { font-size: 12pt; }
    .page-break { page-break-before: always; }
    .no-print { display: none; }
  }
  body {
    font-family: "Times New Roman", Times, serif;
    font-size: 12pt;
    line-height: 1.6;
    color: #111;
    margin: 0 auto;
    max-width: 850px;
    padding: 30px;
    background: #fff;
    text-align: justify;
  }
  h1 {
    font-size: 16pt;
    text-align: center;
    text-transform: uppercase;
    margin-top: 24pt;
    margin-bottom: 12pt;
    font-weight: bold;
    page-break-before: auto;
  }
  h2 {
    font-size: 14pt;
    text-transform: uppercase;
    margin-top: 18pt;
    margin-bottom: 8pt;
    font-weight: bold;
    border-bottom: 1px solid #ddd;
    padding-bottom: 4px;
  }
  h3 {
    font-size: 13pt;
    margin-top: 14pt;
    margin-bottom: 6pt;
    font-weight: bold;
  }
  h4 {
    font-size: 12pt;
    font-weight: bold;
    margin-top: 10pt;
    margin-bottom: 4pt;
  }
  p {
    margin-top: 0;
    margin-bottom: 10pt;
    text-indent: 0.5in;
  }
  .no-indent { text-indent: 0; }
  .center { text-align: center; text-indent: 0; }
  .bold { font-weight: bold; }
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 15pt 0;
    font-size: 10.5pt;
  }
  table, th, td {
    border: 1px solid #333;
  }
  th {
    background-color: #f2f2f2;
    padding: 8px 10px;
    font-weight: bold;
    text-align: center;
  }
  td {
    padding: 6px 10px;
    vertical-align: top;
  }
  ul, ol {
    margin-top: 0;
    margin-bottom: 12pt;
    padding-left: 0.5in;
  }
  li { margin-bottom: 6pt; }
  pre {
    background: #f8f9fa;
    border: 1px solid #ccc;
    padding: 10px 14px;
    font-family: "Courier New", Courier, monospace;
    font-size: 9.5pt;
    line-height: 1.35;
    overflow-x: auto;
    border-radius: 4px;
    text-indent: 0;
  }
  code {
    font-family: "Courier New", Courier, monospace;
    font-size: 10pt;
    background: #f1f1f1;
    padding: 1px 4px;
    border-radius: 3px;
  }
  .fig-caption {
    text-align: center;
    font-style: italic;
    font-size: 11pt;
    margin-top: 8pt;
    margin-bottom: 18pt;
    text-indent: 0;
  }
  .print-btn {
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 12px 24px;
    background: #1b5e20;
    color: #fff;
    border: none;
    border-radius: 6px;
    font-size: 14px;
    font-weight: bold;
    cursor: pointer;
    box-shadow: 0 4px 10px rgba(0,0,0,0.15);
    z-index: 1000;
  }
  .print-btn:hover { background: #0d3813; }
</style>
"""

    lines = md.split("\n")
    html_out = [
        "<!DOCTYPE html>",
        "<html lang='en'>",
        "<head>",
        "<meta charset='UTF-8'>",
        "<title>UZHAVAN - Comprehensive Project Report</title>",
        css,
        "</head>",
        "<body>",
        "<button class='print-btn no-print' onclick='window.print()'>🖨️ Print to PDF / Save as PDF</button>"
    ]

    in_code_block = False
    in_table = False
    in_list = False
    table_lines = []

    def flush_table(tbl_lines):
        if not tbl_lines:
            return ""
        res = ["<table>"]
        is_first = True
        for row in tbl_lines:
            row = row.strip()
            if not row or row.startswith("| ---") or row.startswith("|:---"):
                continue
            cells = [c.strip() for c in row.split("|")[1:-1]]
            res.append("<tr>")
            for c in cells:
                c_html = parse_inlines(c)
                if is_first:
                    res.append(f"<th>{c_html}</th>")
                else:
                    res.append(f"<td>{c_html}</td>")
            res.append("</tr>")
            is_first = False
        res.append("</table>")
        return "\n".join(res)

    def parse_inlines(text):
        text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
        text = re.sub(r'\*(.+?)\*', r'<i>\1</i>', text)
        text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
        text = text.replace("&nbsp;", " ")
        return text

    i = 0
    while i < len(lines):
        line = lines[i]

        if line.strip().startswith("```"):
            if in_code_block:
                html_out.append("</pre>")
                in_code_block = False
            else:
                html_out.append("<pre>")
                in_code_block = True
            i += 1
            continue

        if in_code_block:
            safe_line = line.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            html_out.append(safe_line)
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
                html_out.append(flush_table(table_lines))
                in_table = False
                table_lines = []

        if "<div style=\"page-break-after: always;\"></div>" in line:
            html_out.append("<div class='page-break'></div>")
            i += 1
            continue

        stripped = line.strip()

        if stripped.startswith("# "):
            html_out.append(f"<h1>{parse_inlines(stripped[2:])}</h1>")
        elif stripped.startswith("## "):
            html_out.append(f"<h2>{parse_inlines(stripped[3:])}</h2>")
        elif stripped.startswith("### "):
            html_out.append(f"<h3>{parse_inlines(stripped[4:])}</h3>")
        elif stripped.startswith("#### "):
            html_out.append(f"<h4>{parse_inlines(stripped[5:])}</h4>")
        elif stripped.startswith("- ") or stripped.startswith("• "):
            if not in_list:
                html_out.append("<ul>")
                in_list = True
            html_out.append(f"<li>{parse_inlines(stripped[2:])}</li>")
        elif re.match(r'^\d+\.\s', stripped):
            if not in_list:
                html_out.append("<ol>")
                in_list = True
            item_text = re.sub(r'^\d+\.\s', '', stripped)
            html_out.append(f"<li>{parse_inlines(item_text)}</li>")
        elif stripped == "---":
            html_out.append("<hr style='border: none; border-top: 1px solid #ccc; margin: 20px 0;'>")
        elif stripped == "":
            if in_list:
                html_out.append("</ul>" if "<ul>" in html_out[-2] or "<li>" in html_out[-1] else "</ol>")
                in_list = False
        elif stripped.startswith("*Fig"):
            html_out.append(f"<p class='fig-caption'>{parse_inlines(stripped)}</p>")
        else:
            if in_list:
                html_out.append("</ul>")
                in_list = False
            html_out.append(f"<p>{parse_inlines(stripped)}</p>")

        i += 1

    if in_table:
        html_out.append(flush_table(table_lines))
    if in_list:
        html_out.append("</ul>")

    html_out.append("</body></html>")

    with open(html_path, "w", encoding="utf-8") as f:
        f.write("\n".join(html_out))

    print(f"Comprehensive HTML report successfully generated: {html_path}")

if __name__ == "__main__":
    convert()
