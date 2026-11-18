import io
import csv
import json
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional

from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas

try:
    from ..models import AuditLog
except (ImportError, ValueError):
    from app.models import AuditLog


class NumberedCanvas(canvas.Canvas):
    """
    Two-pass canvas to dynamically compute and print 'Page X of Y' and footer.
    """
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
            self.draw_page_decorations(num_pages)
            super(NumberedCanvas, self).showPage()
        super(NumberedCanvas, self).save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 9)
        self.setFillColor(colors.HexColor("#64748B"))

        # Footer divider
        self.setStrokeColor(colors.HexColor("#E2E8F0"))
        self.setLineWidth(0.8)
        self.line(36, 36, letter[1] - 36 if self._pagesize == landscape(letter) else 792 - 36, 36)

        # Footer left: system confidentiality
        page_width = self._pagesize[0]
        self.drawString(36, 24, "CONFIDENTIAL - AUDIT TRAIL COMPLIANCE REPORT - SYSTEM GENERATED")

        # Footer right: Page X of Y
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(page_width - 36, 24, page_str)
        self.restoreState()


class ReportService:
    @staticmethod
    def generate_csv(records: List[AuditLog], filters: Dict[str, Any]) -> str:
        """
        Generates CSV format string from audit log records.
        """
        output = io.StringIO()
        writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL)

        # Header metadata comment block
        writer.writerow(["# AUDIT LOG EXPORT REPORT"])
        writer.writerow([f"# Generated At: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}"])
        writer.writerow([f"# Applied Filters: {json.dumps(filters)}"])
        writer.writerow([f"# Total Records: {len(records)}"])
        writer.writerow([])

        # Data columns
        headers = [
            "Audit ID",
            "Timestamp (UTC)",
            "Username",
            "User ID",
            "Action Type",
            "Table Name",
            "Record ID",
            "IP Address",
            "Previous Value",
            "New Value"
        ]
        writer.writerow(headers)

        for log in records:
            ts_str = log.timestamp.strftime("%Y-%m-%d %H:%M:%S") if log.timestamp else ""
            writer.writerow([
                log.audit_id,
                ts_str,
                log.username,
                log.user_id if log.user_id is not None else "",
                log.action_type,
                log.table_name,
                log.record_id,
                log.ip_address or "",
                log.previous_value or "",
                log.new_value or ""
            ])

        return output.getvalue()

    @staticmethod
    def generate_pdf(records: List[AuditLog], filters: Dict[str, Any]) -> bytes:
        """
        Generates a professional enterprise PDF audit report using ReportLab.
        Uses Landscape Letter for clean multi-column audit data readability.
        """
        buffer = io.BytesIO()

        # Landscape Letter: 11 x 8.5 inches (792 x 612 pt)
        doc = SimpleDocTemplate(
            buffer,
            pagesize=landscape(letter),
            leftMargin=36,
            rightMargin=36,
            topMargin=36,
            bottomMargin=45
        )

        styles = getSampleStyleSheet()

        # Custom Typography Styles
        title_style = ParagraphStyle(
            'ReportTitle',
            parent=styles['Heading1'],
            fontName='Helvetica-Bold',
            fontSize=20,
            leading=24,
            textColor=colors.HexColor("#0F172A")
        )
        subtitle_style = ParagraphStyle(
            'ReportSubtitle',
            parent=styles['Normal'],
            fontName='Helvetica',
            fontSize=10,
            leading=13,
            textColor=colors.HexColor("#475569")
        )
        section_heading = ParagraphStyle(
            'SectionHeading',
            parent=styles['Heading2'],
            fontName='Helvetica-Bold',
            fontSize=12,
            leading=16,
            textColor=colors.HexColor("#1E293B")
        )
        cell_header_style = ParagraphStyle(
            'CellHeader',
            fontName='Helvetica-Bold',
            fontSize=8,
            leading=10,
            textColor=colors.white,
            alignment=0
        )
        cell_body_style = ParagraphStyle(
            'CellBody',
            fontName='Helvetica',
            fontSize=7.5,
            leading=9.5,
            textColor=colors.HexColor("#1E293B")
        )
        cell_mono_style = ParagraphStyle(
            'CellMono',
            fontName='Courier',
            fontSize=7,
            leading=8.5,
            textColor=colors.HexColor("#334155")
        )

        elements = []

        # Header Title Banner
        gen_time = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        elements.append(Paragraph("Audit Log Report", title_style))
        elements.append(Paragraph(f"Enterprise Security & Compliance Audit Trail  •  Generated: {gen_time}", subtitle_style))
        elements.append(Spacer(1, 10))
        elements.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#1E3A8A"), spaceBefore=2, spaceAfter=10))

        # Filter and Summary Info Block
        start_date = filters.get("start_date") or "All Time"
        end_date = filters.get("end_date") or "Latest"
        action_type = filters.get("action_type") or "ALL OPERATIONS"
        username_filter = filters.get("username") or "ALL USERS"

        insert_count = sum(1 for r in records if r.action_type == "INSERT")
        update_count = sum(1 for r in records if r.action_type == "UPDATE")
        delete_count = sum(1 for r in records if r.action_type == "DELETE")
        total_records = len(records)

        # Summary Metrics Box
        meta_data = [
            [
                Paragraph(f"<b>Date Range:</b> {start_date} to {end_date}", subtitle_style),
                Paragraph(f"<b>Action Filter:</b> {action_type}", subtitle_style),
                Paragraph(f"<b>User Filter:</b> {username_filter}", subtitle_style),
                Paragraph(f"<b>Total Activities:</b> <b>{total_records}</b>", subtitle_style),
            ],
            [
                Paragraph(f"<font color='#059669'><b>INSERT:</b> {insert_count}</font>", subtitle_style),
                Paragraph(f"<font color='#D97706'><b>UPDATE:</b> {update_count}</font>", subtitle_style),
                Paragraph(f"<font color='#DC2626'><b>DELETE:</b> {delete_count}</font>", subtitle_style),
                Paragraph(f"<b>Status:</b> Completed ({total_records} logged)", subtitle_style),
            ]
        ]

        meta_table = Table(meta_data, colWidths=[180, 180, 180, 180])
        meta_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), colors.HexColor("#F8FAFC")),
            ('BOX', (0, 0), (-1, -1), 1, colors.HexColor("#CBD5E1")),
            ('INNERGRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('LEFTPADDING', (0, 0), (-1, -1), 8),
            ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ]))
        elements.append(meta_table)
        elements.append(Spacer(1, 14))

        # Audit Records Table
        elements.append(Paragraph(f"Audit Activity Records ({total_records} items)", section_heading))
        elements.append(Spacer(1, 6))

        # Define Columns for Landscape Letter (usable width = 792 - 72 = 720 pt)
        # Columns: [Audit ID (40), Timestamp (90), User (75), Action (55), Table (65), Record ID (50), IP Address (80), Previous/New Value Details (265)]
        col_widths = [40, 95, 75, 55, 65, 55, 75, 260]

        table_data = [[
            Paragraph("ID", cell_header_style),
            Paragraph("Timestamp (UTC)", cell_header_style),
            Paragraph("Username", cell_header_style),
            Paragraph("Action", cell_header_style),
            Paragraph("Table", cell_header_style),
            Paragraph("Record ID", cell_header_style),
            Paragraph("IP Address", cell_header_style),
            Paragraph("Value Changes / Payload Summary", cell_header_style)
        ]]

        for r in records:
            ts_str = r.timestamp.strftime("%Y-%m-%d %H:%M:%S") if r.timestamp else "-"
            
            # Action styling
            if r.action_type == "INSERT":
                action_p = Paragraph(f"<font color='#059669'><b>INSERT</b></font>", cell_body_style)
            elif r.action_type == "UPDATE":
                action_p = Paragraph(f"<font color='#B45309'><b>UPDATE</b></font>", cell_body_style)
            elif r.action_type == "DELETE":
                action_p = Paragraph(f"<font color='#DC2626'><b>DELETE</b></font>", cell_body_style)
            else:
                action_p = Paragraph(r.action_type, cell_body_style)

            # Details formatting
            detail_text = ""
            if r.action_type == "INSERT" and r.new_value:
                detail_text = f"<b>NEW:</b> {r.new_value[:180]}{'...' if len(r.new_value) > 180 else ''}"
            elif r.action_type == "DELETE" and r.previous_value:
                detail_text = f"<b>PREV:</b> {r.previous_value[:180]}{'...' if len(r.previous_value) > 180 else ''}"
            elif r.action_type == "UPDATE":
                p_short = (r.previous_value[:80] + '...') if r.previous_value and len(r.previous_value) > 80 else (r.previous_value or "")
                n_short = (r.new_value[:80] + '...') if r.new_value and len(r.new_value) > 80 else (r.new_value or "")
                detail_text = f"<b>PREV:</b> {p_short}<br/><b>NEW:</b> {n_short}"
            else:
                detail_text = "-"

            row = [
                Paragraph(str(r.audit_id), cell_body_style),
                Paragraph(ts_str, cell_body_style),
                Paragraph(r.username, cell_body_style),
                action_p,
                Paragraph(r.table_name, cell_body_style),
                Paragraph(str(r.record_id), cell_body_style),
                Paragraph(r.ip_address or "-", cell_body_style),
                Paragraph(detail_text, cell_mono_style)
            ]
            table_data.append(row)

        if len(records) == 0:
            table_data.append([
                Paragraph("No audit log records match the selected filter criteria.", cell_body_style),
                "", "", "", "", "", "", ""
            ])

        audit_table = Table(table_data, colWidths=col_widths, repeatRows=1)
        t_style = [
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor("#1E293B")),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('LEFTPADDING', (0, 0), (-1, -1), 4),
            ('RIGHTPADDING', (0, 0), (-1, -1), 4),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E1")),
        ]

        # Alternating row background colors
        for i in range(1, len(table_data)):
            if i % 2 == 0:
                t_style.append(('BACKGROUND', (0, i), (-1, i), colors.HexColor("#F8FAFC")))
            else:
                t_style.append(('BACKGROUND', (0, i), (-1, i), colors.white))

        if len(records) == 0:
            t_style.append(('SPAN', (0, 1), (-1, 1)))

        audit_table.setStyle(TableStyle(t_style))
        elements.append(audit_table)

        # Build document with NumberedCanvas
        doc.build(elements, canvasmaker=NumberedCanvas)
        buffer.seek(0)
        return buffer.getvalue()

