require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class MaintenanceWorkflowTest < ActionDispatch::IntegrationTest

  test "full maintenance workflow" do
    login_king
    
    visit(project_show_path(project: "BaseDistro"))

    find(:id, "advanced_tabs_trigger").click
    find(:link, "Attributes").click
    find(:id, "add-new-attribute").click
    find(:id, 'attribute').select("OBS:Maintained")
    find_button("Save attribute").click

    logout
    # now let tom branch a package
    login_tom

    visit(project_show_path(project: "My:Maintenance"))
    assert_equal "official maintenance space", find(:id, "project_title").text
    
    assert find(:id, "infos_list").has_text? %r{3 maintained projects}

    find(:link, "maintained projects").click
    find(:link, "BaseDistro2.0:LinkedUpdateProject").click
    
    assert find(:css, "#infos_list").has_text? %r{Maintained by My:Maintenance}
    first(:link, "pack2").click
    find(:link, "Branch package").click
    
    assert find(:css, "#branch_dialog").has_text? %r{Do you really want to branch package}
    find_button("Ok").click

    assert find(:css, "#flash-messages").has_text? %r{Branched package BaseDistro2\.0:LinkedUpdateProject.*pack2}

    visit(project_show_path(project: "home:tom"))

    find(:link, "Subprojects").click
    find(:link, "branches:BaseDistro2.0:LinkedUpdateProject").click
    find(:link, "Submit as update").click
    
    # wait for the dialog to appear
    assert find(:css, ".dialog h2").has_content? "Submit as Update"
    fill_in "description", with: "I want the update"
    find_button("Ok").click

    assert_equal "Created maintenance release request", find(:css, "span.ui-icon.ui-icon-info").text
    assert_equal "open request", find(:link, "open request").text
    assert_equal "1 Release Target", find(:link, "1 Release Target").text

    find(:link, "Create patchinfo").click
    fill_in "summary", with: "Nada"
    fill_in "description", with: "Fixes nothing"
    find(:id, 'rating').select("critical")
    find(:id, "relogin").click
    find(:id, "reboot").click
    find(:id, "zypp_restart_needed").click
    find(:id, "block").click
    fill_in "block_reason", with: "locked!"
    find_button("Save Patchinfo").click

    assert find(:css, "span.ui-icon.ui-icon-alert").has_text? %r{Summary is too short}
    fill_in "summary", with: "pack2 is much better than the old one"
    find_button("Save Patchinfo").click
    
    assert find(:css, "span.ui-icon.ui-icon-alert").has_text? %r{Description is too short}
    fill_in "description", with: "Fixes nothing, Fixes nothing, Fixes nothing, Fixes nothing, Fixes nothing, Fixes nothing"
    fill_in "issue", with: "bnc#27272"
    find(:css, "img[alt=\"Add Bug\"]").click
    find_button("Save Patchinfo").click
    
    # summary and description are ok now
    assert first(:css, "span.ui-icon.ui-icon-alert").nil?

    assert_equal "Successfully edited patchinfo", find(:css, "span.ui-icon.ui-icon-info").text
    assert_equal "This update is currently blocked:", find(:css, ".ui-state-error b").text

    logout

    # now let the coordinator act
    login_user("maintenance_coord", "power")
    visit(project_show_path(project: "My:Maintenance"))    
    
    find(:link, "open request").click
    assert_equal "I want the update", find(:id, "description_text").text
    fill_in "reason", with: "really? ok"
    find(:id, "accept_request_button").click
    assert find(:css, "#action_display_0").has_text? %r{Submit update from package home:tom:branches:BaseDistro2.0:LinkedUpdateProject / pack2 to project My:Maintenance:0}

    visit(project_show_path(project: "My:Maintenance:0"))
    find(:link, "Patchinfo present").click
    find(:id, "edit-patchinfo").click
    # TODO: need to find out if this is correct or buggy
    if false

    assert_equal "Fixes nothing", find(:id, "summary").text
    find(:id, "summary").clear
    find(:id, "summary").send_keys "pack2: Fixes nothing"
    find(:name, "commit").click
    wait_for_page
    find(:link, "My:Maintenance").click
    find(:link, "open incident").click
    Selenium::WebDriver::Support::Select.new(find(:id, "incident_type_select")).select_by(:text, "closed")
    Selenium::WebDriver::Support::Select.new(find(:id, "incident_type_select")).select_by(:text, "open")
    find(:link, "recommended").click
    find(:id, "edit-patchinfo").click
    find(:id, "block").click
    find(:id, "block_reason").clear
    find(:id, "block_reason").send_keys "blocking"
    find(:name, "commit").click
    wait_for_page
    assert_equal "This update is currently blocked:", find(:css, "b").text
    find(:link, "My:Maintenance").click
    find(:link, "Incidents").click
    find(:link, "0").click
    find(:link, "Request to release").click
    wait_for_javascript
    find(:id, "description").clear
    find(:id, "description").send_keys "RELEASE!"
    find(:name, "commit").click
    wait_for_page
    
    # we can't release without build results
    assert_equal "The repository 'My:Maintenance:0' / 'BaseDistro2.0_LinkedUpdateProject' / i586", find(:css, "span.ui-icon.ui-icon-alert").text
    end
  end
  
end
