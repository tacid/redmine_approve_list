
  approve_user = function() {
      if ($(this).prop("checked")) {
        label=$(this).closest('label');
        $('#users_added').append(label);
        label.wrap('<li></li>');
      }else{
        label=$(this).closest('label');
        if ( label.parent().is("li") ) { label.unwrap() }
        $('#users_for_approver').prepend(label);
      }
  }
