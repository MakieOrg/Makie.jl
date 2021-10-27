using GLMakie, Dates

time = Time("11:11:55.914")
date = Date("2021-10-27")
date_time = DateTime("2021-10-27T11:11:55.914")
time_range = range(time, step=Second(5), length=10)
date_range = range(date, step=Day(5), length=10)
date_time_range = range(date_time, step=Week(5), length=10)
scatter(time_range, 1:10)
scatter(date_range, 1:10)
scatter(date_time_range, 1:10)


date_time_range = range(date_time, step=Second(5), length=10)
scatter(date_time_range, 1:10)
scatter!(time_range, 1:10)
