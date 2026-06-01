Mix.Task.run("app.start")
MailglassDemo.DemoData.reset!()
IO.puts("Seeded Mailglass demo data for tenant #{MailglassDemo.DemoData.tenant_id()}")
