$(function() {
  $inputs = $('input.form-check-input');
  $inputs.prop('disabled', false);

  $('form').change(function() {
    var state = $inputs.map(function() {
      return $(this).is(':checked') ? 1 : 0;
    }).get().join('');

    $('input[name=state]').val(state);
  });
});
