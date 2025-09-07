#!/usr/bin/env python3
"""
自動修復Xcode項目 - 添加缺失的文件到項目中
"""

import os
import re
import uuid

def generate_uuid():
    """生成Xcode項目文件使用的UUID格式"""
    return ''.join(str(uuid.uuid4()).replace('-', '').upper()[:24])

def fix_xcode_project():
    """修復Xcode項目文件"""
    project_file = "KitchenAssistant.xcodeproj/project.pbxproj"
    
    if not os.path.exists(project_file):
        print("❌ 找不到項目文件")
        return False
    
    # 備份原始文件
    backup_file = project_file + ".backup"
    if not os.path.exists(backup_file):
        os.system(f"cp {project_file} {backup_file}")
        print("✅ 已備份原始項目文件")
    
    # 讀取項目文件
    with open(project_file, 'r') as f:
        content = f.read()
    
    # 生成新的UUID
    recipe_file_ref = generate_uuid()
    recipe_view_file_ref = generate_uuid()
    image_picker_file_ref = generate_uuid()
    
    recipe_build_file = generate_uuid()
    recipe_view_build_file = generate_uuid()
    image_picker_build_file = generate_uuid()
    
    models_group = generate_uuid()
    utils_group = generate_uuid()
    
    # 1. 添加PBXBuildFile條目
    build_files_section = f"""/* Begin PBXBuildFile section */
		A41234561234567890ABCDEF /* KitchenAssistantApp.swift in Sources */ = {{isa = PBXBuildFile; fileRef = A41234551234567890ABCDEF /* KitchenAssistantApp.swift */; }};
		A41234581234567890ABCDEF /* ContentView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = A41234571234567890ABCDEF /* ContentView.swift */; }};
		A4123459123456789ABCDEF0 /* CameraView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = A4123458123456789ABCDEF0 /* CameraView.swift */; }};
		A412345A123456789ABCDEF0 /* APIClient.swift in Sources */ = {{isa = PBXBuildFile; fileRef = A4123459123456789ABCDEF1 /* APIClient.swift */; }};
		A412345B123456789ABCDEF0 /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = A412345A123456789ABCDEF1 /* Assets.xcassets */; }};
		{recipe_build_file} /* Recipe.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {recipe_file_ref} /* Recipe.swift */; }};
		{recipe_view_build_file} /* RecipeView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {recipe_view_file_ref} /* RecipeView.swift */; }};
		{image_picker_build_file} /* ImagePicker.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {image_picker_file_ref} /* ImagePicker.swift */; }};
/* End PBXBuildFile section */"""
    
    # 2. 添加PBXFileReference條目
    file_refs_section = f"""/* Begin PBXFileReference section */
		A41234521234567890ABCDEF /* KitchenAssistant.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = KitchenAssistant.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		A41234551234567890ABCDEF /* KitchenAssistantApp.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = KitchenAssistantApp.swift; sourceTree = "<group>"; }};
		A41234571234567890ABCDEF /* ContentView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; }};
		A4123458123456789ABCDEF0 /* CameraView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CameraView.swift; sourceTree = "<group>"; }};
		A4123459123456789ABCDEF1 /* APIClient.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = APIClient.swift; sourceTree = "<group>"; }};
		A412345A123456789ABCDEF1 /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
		A412345C123456789ABCDEF1 /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
		{recipe_file_ref} /* Recipe.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Recipe.swift; sourceTree = "<group>"; }};
		{recipe_view_file_ref} /* RecipeView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RecipeView.swift; sourceTree = "<group>"; }};
		{image_picker_file_ref} /* ImagePicker.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ImagePicker.swift; sourceTree = "<group>"; }};
/* End PBXFileReference section */"""
    
    # 3. 添加Groups
    groups_section = f"""		A41234541234567890ABCDEF /* KitchenAssistant */ = {{
			isa = PBXGroup;
			children = (
				A41234551234567890ABCDEF /* KitchenAssistantApp.swift */,
				{models_group} /* Models */,
				A4123460123456789ABCDEF /* Views */,
				A4123461123456789ABCDEF /* Services */,
				{utils_group} /* Utils */,
				A412345A123456789ABCDEF1 /* Assets.xcassets */,
				A412345C123456789ABCDEF1 /* Info.plist */,
			);
			path = KitchenAssistant;
			sourceTree = "<group>";
		}};
		{models_group} /* Models */ = {{
			isa = PBXGroup;
			children = (
				{recipe_file_ref} /* Recipe.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		}};
		A4123460123456789ABCDEF /* Views */ = {{
			isa = PBXGroup;
			children = (
				A41234571234567890ABCDEF /* ContentView.swift */,
				A4123458123456789ABCDEF0 /* CameraView.swift */,
				{recipe_view_file_ref} /* RecipeView.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		}};
		A4123461123456789ABCDEF /* Services */ = {{
			isa = PBXGroup;
			children = (
				A4123459123456789ABCDEF1 /* APIClient.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		}};
		{utils_group} /* Utils */ = {{
			isa = PBXGroup;
			children = (
				{image_picker_file_ref} /* ImagePicker.swift */,
			);
			path = Utils;
			sourceTree = "<group>";
		}};"""
    
    # 4. 添加Sources構建階段
    sources_section = f"""		A412344E1234567890ABCDEF /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				A41234581234567890ABCDEF /* ContentView.swift in Sources */,
				A4123459123456789ABCDEF0 /* CameraView.swift in Sources */,
				A412345A123456789ABCDEF0 /* APIClient.swift in Sources */,
				A41234561234567890ABCDEF /* KitchenAssistantApp.swift in Sources */,
				{recipe_build_file} /* Recipe.swift in Sources */,
				{recipe_view_build_file} /* RecipeView.swift in Sources */,
				{image_picker_build_file} /* ImagePicker.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};"""
    
    # 替換內容
    content = re.sub(r'/\* Begin PBXBuildFile section \*/.*?/\* End PBXBuildFile section \*/', 
                    build_files_section, content, flags=re.DOTALL)
    
    content = re.sub(r'/\* Begin PBXFileReference section \*/.*?/\* End PBXFileReference section \*/', 
                    file_refs_section, content, flags=re.DOTALL)
    
    content = re.sub(r'/\* Begin PBXGroup section \*/.*?/\* End PBXGroup section \*/', 
                    f'/* Begin PBXGroup section */\n{groups_section}\n/* End PBXGroup section */', content, flags=re.DOTALL)
    
    content = re.sub(r'/\* Begin PBXSourcesBuildPhase section \*/.*?/\* End PBXSourcesBuildPhase section \*/', 
                    f'/* Begin PBXSourcesBuildPhase section */\n{sources_section}\n/* End PBXSourcesBuildPhase section */', content, flags=re.DOTALL)
    
    # 寫入修改後的文件
    with open(project_file, 'w') as f:
        f.write(content)
    
    print("✅ 已修復Xcode項目文件")
    print("📁 添加的文件:")
    print("   - Recipe.swift → Models 文件夾")
    print("   - RecipeView.swift → Views 文件夾") 
    print("   - ImagePicker.swift → Utils 文件夾")
    
    return True

if __name__ == "__main__":
    print("🔧 開始自動修復Xcode項目...")
    if fix_xcode_project():
        print("✅ 修復完成！請在Xcode中按 ⌘+B 構建項目")
    else:
        print("❌ 修復失敗")
