# Screen Specification Generation Instructions (v2.1)

## Overview

This document provides technical instructions for generating structured screen specification documents from messy Markdown files (typically copied from Google Sheets).

**Goal**: Transform unstructured input into well-organized documentation following `SCREEN_DETAIL_TEMPLATE v2.1` while preserving all original text exactly.

---

## Table of Contents

1. [Input Format](#input-format)
2. [Output Format](#output-format)
3. [Processing Algorithm](#processing-algorithm)
4. [Formatting Rules](#formatting-rules)
5. [Validation](#validation)
6. [Examples](#examples)
7. [Version 2.1 Structure](#version-21-structure)

---

## Input Format

### Expected Input Structure

The input file typically contains two main sections:

1. **処理概要 / Screen Overview**
   - Japanese description (labeled `JP:`)
   - English description (labeled `EN:`)
   - Separated by blank lines or `=====`

2. **Item Definition / 項目定義**
   - Table with columns:
     - Item No., 項目名 (JP/EN), 項目種別, 必須 (〇, △, -), データ型, 桁数, フォーマット, 初期値, 説明 (JP/EN)

3. **Action and Screen Transition / アクション及び画面遷移**
   - Table with columns:
     - ID, Item No., トリガー (JP/EN), 画面遷移, アクション概要 (JP/EN), 備考

---

## Output Format

### Required Structure (v2.1)

Follow `SCREEN_DETAIL_TEMPLATE v2.1` exactly - **4 sections**:

```markdown
> **Mã màn hình:** `[code]`
> **Tên màn hình:** `[name]`
> **Mô tả ngắn:** [1-2 sentence description]
> **Ngày tạo:** YYYY-MM-DD
> **Ngày cập nhật cuối:** YYYY-MM-DD
> **Phiên bản:** 2.1

---

## Mục lục
- [1. Tổng quan](#1-tổng-quan)
- [2. Chi tiết màn hình](#2-chi-tiết-màn-hình)
- [3. Luồng tương tác](#3-luồng-tương-tác)
- [4. Validation procedures detail](#4-validation-procedures-detail)

---

## 1. Tổng quan
### 1.1 Mục đích
### 1.2 Đối tượng sử dụng màn hình (Role)

## 2. Chi tiết màn hình

#### Section [N] – [Name]:
| STT | Tên thành phần | Loại | Bắt buộc | Mặc định | Mô tả | Action |
| --- | -------------- | ---- | -------- | -------- | ----- | ------ |

## 3. Luồng tương tác
### 3.1 Các Bước Thao Tác
### 3.2 Các Màn Hình Liên Quan

## 4. Validation procedures detail
### 4.1 Quy tắc chung (màn hình)
### 4.2 Ràng buộc & Error Codes
### Field-level Validation
```

---

## Processing Algorithm

### Step 1: Parse Input File

```python
def parse_input(file_content):
    sections = {
        'overview': extract_overview(file_content),
        'items': extract_item_definition_table(file_content),
        'actions': extract_action_table(file_content)
    }
    return sections
```

### Step 2: Extract Metadata

```python
def extract_metadata(sections):
    return {
        'screen_code': infer_screen_code(sections['overview']),
        'screen_name': extract_screen_name(sections['overview']),
        'short_description': extract_short_desc(sections['overview']['en'], 1-2 sentences),
        'created_date': get_today_date(),
        'updated_date': get_today_date(),
        'version': '2.1'
    }
```

### Step 3: Group Items Logically

```python
def group_items_by_logic(items):
    groups = {
        'main_ui': [],      # Main screen components
        'actions': [],      # Buttons, links
        'popups': [],       # Popups, dialogs, modals
        'navigation': []    # Navigation elements
    }
    
    for item in items:
        group = determine_group(item['type'], item['name'])
        groups[group].append(item)
    
    return groups
```

### Step 4: Transform to v2.1 Table Structure

```python
def transform_to_v21_table(items):
    """
    Structure: STT | Tên | Loại | Bắt buộc | Mặc định | Mô tả | Action
    """
    transformed = []
    
    for item in items:
        # Build combined Mô tả
        description_parts = []
        
        # Add data type info if exists
        if item.get('data_type'):
            description_parts.append(f"**Data type:** {item['data_type']}")
        if item.get('length'):
            description_parts.append(f"**Length:** {item['length']} chars")
        if item.get('format'):
            description_parts.append(f"**Format:** {item['format']}")
        
        # Add original descriptions
        if item.get('description_jp'):
            description_parts.append(f"**JP:** {item['description_jp']}")
        if item.get('description_en'):
            description_parts.append(f"**EN:** {item['description_en']}")
        
        combined_description = "<br>".join(description_parts)
        
        # Infer action
        action = infer_action(item['type'], item.get('actions'))
        
        transformed.append({
            'stt': item['no'],
            'name': item['name'],
            'type': item['type'],
            'required': item['required'],
            'default': item.get('initial_value', '—'),
            'description': combined_description,
            'action': action
        })
    
    return transformed

def infer_action(item_type, action_data):
    """Infer user action based on component type"""
    action_map = {
        'Text box': 'Enter/Paste',
        'Button': 'Click',
        'Link': 'Click',
        'Dropdown': 'Select',
        'List': 'View/Scroll',
        'Dialog': 'View',
        'Text': '—'
    }
    
    # Use action data if available
    if action_data:
        return extract_action_verb(action_data)
    
    # Otherwise use default mapping
    return action_map.get(item_type, '—')
```

### Step 5: Generate Section 2 (Chi tiết màn hình)

```python
def generate_section_2(items):
    # Group items by logical sections
    grouped = group_items_by_logic(items)
    
    # Transform to v2.1 structure
    transformed_groups = {}
    for group_name, group_items in grouped.items():
        transformed_groups[group_name] = transform_to_v21_table(group_items)
    
    sections = []
    section_num = 1
    
    output = "## 2. Chi tiết màn hình\n\n"
    
    for section_name, section_items in transformed_groups.items():
        if not section_items:
            continue
            
        # Direct to section table - no subsections
        section = f"#### Section {section_num} – {format_section_name(section_name)}:\n"
        section += "| STT | Tên thành phần | Loại | Bắt buộc | Mặc định | Mô tả | Action |\n"
        section += "|---|---|---|---|---|---|---|\n"
        
        for item in section_items:
            row = f"| {item['stt']} | {item['name']} | {item['type']} | {item['required']} | {item['default']} | {item['description']} | {item['action']} |\n"
            section += row
        
        section += "\n"
        sections.append(section)
        section_num += 1
    
    output += "\n".join(sections)
    return output
```

### Step 6: Generate Section 4 (Validation)

```python
def generate_section_4(items, actions):
    """
    Section 4: Validation procedures detail
    """
    output = "## 4. Validation procedures detail\n\n"
    
    # 4.1 Quy tắc chung
    output += "### 4.1 Quy tắc chung (màn hình)\n"
    general_rules = extract_general_rules(items, actions)
    for rule in general_rules:
        output += f"- {rule}\n"
    output += "\n"
    
    # 4.2 Ràng buộc & Error Codes
    output += "### 4.2 Ràng buộc & Error Codes\n"
    error_codes = extract_error_codes(items, actions)
    for code, desc in error_codes.items():
        output += f"- **{code}**: {desc}\n"
    output += "\n"
    
    # Field-level Validation
    output += "### Field-level Validation\n"
    output += "| Field | Rule |\n"
    output += "|---|---|\n"
    
    field_validations = extract_field_validations(items)
    for field, rule in field_validations.items():
        output += f"| {field} | {rule} |\n"
    
    return output
```

---

## Formatting Rules

### Critical Rules (MUST FOLLOW)

1. **Text Preservation**: Never modify original text
2. **Version**: Must be `2.1`
3. **4 Sections**: Only 4 sections in mục lục
4. **No Subsections in Section 2**: Direct to Section tables
5. **Table Structure**: `STT | Tên | Loại | Bắt buộc | Mặc định | Mô tả | Action`

### Mô tả Column Format

```python
def format_description(item):
    parts = []
    
    # Data type info
    if item['data_type']:
        parts.append(f"**Data type:** {item['data_type']}")
    if item['length']:
        parts.append(f"**Length:** {item['length']} chars")
    if item['format']:
        parts.append(f"**Format:** {item['format']}")
    
    # Descriptions
    if item['description_jp']:
        parts.append(f"**JP:** {item['description_jp']}")
    if item['description_en']:
        parts.append(f"**EN:** {item['description_en']}")
    
    return "<br>".join(parts)
```

---

## Validation

### Pre-Output Checklist

```python
def validate_output(generated):
    checks = [
        verify_version_is_21(generated),
        verify_4_sections(generated),
        verify_no_subsections_in_section_2(generated),
        verify_table_structure_v21(generated),
        verify_action_column_exists(generated),
        verify_no_separate_tai_lieu_lien_quan(generated)
    ]
    
    return all(checks)

def verify_4_sections(generated):
    # Check mục lục has exactly 4 sections
    pattern = r'## Mục lục.*?- \[1\. Tổng quan\].*?- \[2\. Chi tiết màn hình\].*?- \[3\. Luồng tương tác\].*?- \[4\. Validation'
    if not re.search(pattern, generated, re.DOTALL):
        raise ValidationError("Mục lục must have exactly 4 sections")
    return True

def verify_no_subsections_in_section_2(generated):
    # Section 2 should start with "#### Section 1 –", not "### 2.1"
    section_2_pattern = r'## 2\. Chi tiết màn hình\s*\n\s*####'
    if not re.search(section_2_pattern, generated):
        raise ValidationError("Section 2 should start directly with Section tables")
    return True
```

---

## Examples

### Example 1: Item Transformation (v2.1)

**Input**:
```
Item No. | 項目名 - JP | 項目名 - EN | 必須 | データ型 | 桁数 | 説明 - JP | 説明 - EN
1 | メールアドレス | Email address | 〇 | String | 254 | HCK-001が表示 | HCK-001 is displayed
```

**Output**:
```markdown
## 2. Chi tiết màn hình

#### Section 1 – Main Components:

| STT | Tên thành phần | Loại | Bắt buộc | Mặc định | Mô tả | Action |
|---|---|---|---|---|---|---|
| 1 | メールアドレス / Email address | Text box | 〇 | - | **Data type:** String, **Length:** 254 chars<br>**JP:** HCK-001が表示<br>**EN:** HCK-001 is displayed | Enter/Paste |
```

### Example 2: Complete Document Structure

```markdown
# SCREEN DETAIL: ULO_01 – ログイン（Login）

> **Mã màn hình:** `ULO_01`  
> **Tên màn hình:** `ログイン（Login）`  
> **Mô tả ngắn:** Users log in with email/phone and password.  
> **Ngày tạo:** 2025-10-29  
> **Ngày cập nhật cuối:** 2025-10-29  
> **Phiên bản:** 2.1

---

## Mục lục
- [1. Tổng quan](#1-tổng-quan)
- [2. Chi tiết màn hình](#2-chi-tiết-màn-hình)
- [3. Luồng tương tác](#3-luồng-tương-tác)
- [4. Validation procedures detail](#4-validation-procedures-detail)

---

## 1. Tổng quan

### 1.1 Mục đích
[Content]

### 1.2 Đối tượng sử dụng màn hình (Role)
[Content]

---

## 2. Chi tiết màn hình

#### Section 1 – Login Form:
[Table]

#### Section 2 – Popups:
[Table]

---

## 3. Luồng tương tác

### 3.1 Các Bước Thao Tác
[Content]

### 3.2 Các Màn Hình Liên Quan
[Content]

---

## 4. Validation procedures detail

### 4.1 Quy tắc chung (màn hình)
[Content]

### 4.2 Ràng buộc & Error Codes
[Content]

### Field-level Validation
[Table]

---

## End of Document
```

---

## Version 2.1 Structure

### Key Changes from Previous Versions:

1. **4 sections** (simplified from 5 or 10)
2. **No "Tài liệu liên quan" section** - integrated into other sections
3. **Section 2 direct to tables** - no "3.1 Các Thành Phần Chính" subsections
4. **Simpler table structure** - 7 columns
5. **Merged data fields** - Data type info in Mô tả column

### Section Mapping:

```
v2.1                              Content
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Tổng quan                      Overview, purpose, roles
2. Chi tiết màn hình              All UI components in section tables
3. Luồng tương tác                Interaction flow, related screens
4. Validation procedures detail   All validation, rules, errors
```

---

## Related Documents

- **Template**: `docs/business/screen_spec/screen_spec_template.md` (v2.1)
- **Guidelines**: `docs/business/screen_spec/screen_spec_template_guidelines.md`
- **Example**: `docs/business/screen_spec/screen_spec_example.md`
- **Formatting Rules**: `.cursor/rules/screen_spec_formatting.mdc` (v2.1)
- **Command**: `.cursor/commands/generate-screen-spec.md`

---

**Version**: 2.1  
**Last Updated**: 2025-10-29  
**Maintained by**: Development Team
