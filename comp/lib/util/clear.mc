<%doc>

A quick tool to cleart cache

</%doc>


<%init>

%HTML::Mason::Commands::session = ();

</%init>

<html>

<body>

Should be cleared

<& '/widgets/debug/debug.mc' &>


</body>

</html>
