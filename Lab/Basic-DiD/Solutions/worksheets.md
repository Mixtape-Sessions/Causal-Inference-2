# Basic DID Worksheet

<table>
	<colgroup>
		<col style="width: 18%" />
		<col style="width: 17%" />
		<col style="width: 17%" />
		<col style="width: 17%" />
		<col style="width: 15%" />
		<col style="width: 14%" />
	</colgroup>
	<thead>
		<tr class="header">
			<th><strong>Person</strong></th>
			<th>$Y(1)$</th>
			<th>$Y(0)$</th>
			<th>$\delta$</th>
			<th>$Y$</th>
			<th>$D$</th>
		</tr>
	</thead>
	<tbody>
		<tr class="odd">
			<td>Alice</td>
			<td>15</td>
			<td>12</td>
			<td>3</td>
			<td>12</td>
			<td>0</td>
		</tr>
		<tr class="even">
			<td>Bob</td>
			<td>5</td>
			<td>10</td>
			<td>-5</td>
			<td>5</td>
			<td>1</td>
		</tr>
		<tr class="odd">
			<td>Chad</td>
			<td>17</td>
			<td>11</td>
			<td>6</td>
			<td>11</td>
			<td>0</td>
		</tr>
		<tr class="even">
			<td>Derrick</td>
			<td>10</td>
			<td>9</td>
			<td>1</td>
			<td>9</td>
			<td>0</td>
		</tr>
		<tr class="odd">
			<td>Edith</td>
			<td>9</td>
			<td>9</td>
			<td>0</td>
			<td>9</td>
			<td>0</td>
		</tr>
		<tr class="even">
			<td>Frank</td>
			<td>1</td>
			<td>5</td>
			<td>-4</td>
			<td>1</td>
			<td>1</td>
		</tr>
		<tr class="odd">
			<td>George</td>
			<td>13</td>
			<td>9</td>
			<td>4</td>
			<td>9</td>
			<td>0</td>
		</tr>
		<tr class="even">
			<td>Hannah</td>
			<td>10</td>
			<td>8</td>
			<td>2</td>
			<td>8</td>
			<td>0</td>
		</tr>
		<tr class="odd">
			<td>Ida</td>
			<td>9</td>
			<td>12</td>
			<td>-3</td>
			<td>9</td>
			<td>1</td>
		</tr>
		<tr class="even">
			<td>Janice</td>
			<td>8</td>
			<td>15</td>
			<td>-7</td>
			<td>8</td>
			<td>1</td>
		</tr>
	</tbody>
</table>

The above table is a table of potential outcomes for 10 people where the treatment is an app meditation exercise that is supposed to reduce your anxiety. Anxiety is measured on a scale of 1 to 20, with higher numbers being higher levels of anxiety. It is measured using a wearable watch and uploaded to your phone.

1.  Calculate the individual treatment effect and comment "is this app good or bad for the person?"

**Answer:** See table

2.  Calculate the average treatment effect by averaging over delta. Is the app on average good for people? What does the average mean?

**Answer:** The average of $\delta_i$ is -0.3 which means that on average the app is good for people. On average, anxiety levels go down by 0.3 units.

3.  Assume that the "perfect doctor" gives the app only to people whose $\delta$ is negative (i.e., $\delta < 0$). Fill out D with who gets the app and who gets nothing

**Answer:** See table

4.  Calculate the ATT and compare it with the ATE. Why is it different?

**Answer:** The ATT under the "perfect doctor" is -4.75 (average of -5, -4, -3, and -7). The ATE is -0.3. The ATT is different because the "perfect doctor" is only giving the app to people who are helped by it. The ATE is the average of everyone, including those who are hurt by the app.

---
<table>
	<colgroup>
		<col style="width: 11%" />
		<col style="width: 13%" />
		<col style="width: 13%" />
		<col style="width: 13%" />
		<col style="width: 11%" />
		<col style="width: 14%" />
		<col style="width: 18%" />
		<col style="width: 1%" />
	</colgroup>
	<thead>
		<tr class="header">
			<th></th>
			<th></th>
			<th colspan="2"><strong>ATT STUFF</strong></th>
			<th colspan="2"><strong>DID STUFF</strong></th>
			<th></th>
			<th></th>
		</tr>
	</thead>
	<tbody>
		<tr class="odd">
			<td><strong>year</strong></td>
			<td><strong>group</strong></td>
			<td>$y^1$</td>
			<td>$y^0$</td>
			<td>$y$</td>
			<td>$D$</td>
			<td><strong>Pre/Post</strong></td>
      <td>$\delta$</td>
		</tr>
		<tr class="even">
			<td>1980</td>
			<td>1</td>
			<td></td>
			<td>3.58</td>
			<td>3.58</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="odd">
			<td>1981</td>
			<td>1</td>
			<td></td>
			<td>4.52</td>
			<td>4.52</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="even">
			<td>1982</td>
			<td>1</td>
			<td></td>
			<td>5.57</td>
			<td>5.57</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="odd">
			<td>1983</td>
			<td>1</td>
			<td></td>
			<td>6.53</td>
			<td>6.53</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="even">
			<td>1984</td>
			<td>1</td>
			<td></td>
			<td>7.57</td>
			<td>7.57</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="odd">
			<td>1985</td>
			<td>1</td>
			<td></td>
			<td>8.56</td>
			<td>8.56</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="even">
			<td>1986</td>
			<td>1</td>
			<td>19.55</td>
			<td><strong>9.56</strong></td>
			<td>19.55</td>
			<td>1</td>
			<td>Post</td>
			<td>9.99</td>
		</tr>
		<tr class="odd">
			<td>1987</td>
			<td>1</td>
			<td>30.59</td>
			<td><strong>10.59</strong></td>
			<td>30.59</td>
			<td>1</td>
			<td>Post</td>
			<td>20</td>
		</tr>
		<tr class="even">
			<td>1988</td>
			<td>1</td>
			<td>41.55</td>
			<td><strong>11.53</strong></td>
			<td>41.55</td>
			<td>1</td>
			<td>Post</td>
			<td>30.02</td>
		</tr>
		<tr class="odd">
			<td>1989</td>
			<td>1</td>
			<td>52.57</td>
			<td><strong>12.58</strong></td>
			<td>52.57</td>
			<td>1</td>
			<td>Post</td>
			<td>39.99</td>
		</tr>
		<tr class="even">
			<td>1990</td>
			<td>1</td>
			<td>63.56</td>
			<td><strong>13.56</strong></td>
			<td>63.56</td>
			<td>1</td>
			<td>Post</td>
			<td>50</td>
		</tr>
		<tr class="odd">
			<td>1980</td>
			<td>2</td>
			<td></td>
			<td>3.59</td>
			<td>3.59</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="even">
			<td>1981</td>
			<td>2</td>
			<td></td>
			<td>4.56</td>
			<td>4.56</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="odd">
			<td>1982</td>
			<td>2</td>
			<td></td>
			<td>5.59</td>
			<td>5.59</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="even">
			<td>1983</td>
			<td>2</td>
			<td></td>
			<td>6.54</td>
			<td>6.54</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="odd">
			<td>1984</td>
			<td>2</td>
			<td></td>
			<td>7.55</td>
			<td>7.55</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="even">
			<td>1985</td>
			<td>2</td>
			<td></td>
			<td>8.58</td>
			<td>8.58</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="odd">
			<td>1986</td>
			<td>2</td>
			<td></td>
			<td>9.58</td>
			<td>9.58</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="even">
			<td>1987</td>
			<td>2</td>
			<td></td>
			<td>10.58</td>
			<td>10.58</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="odd">
			<td>1988</td>
			<td>2</td>
			<td></td>
			<td>11.62</td>
			<td>11.62</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="even">
			<td>1989</td>
			<td>2</td>
			<td></td>
			<td>12.58</td>
			<td>12.58</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
		<tr class="odd">
			<td>1990</td>
			<td>2</td>
			<td></td>
			<td>13.58</td>
			<td>13.58</td>
			<td>0</td>
			<td>Pre</td>
			<td></td>
		</tr>
	</tbody>
</table>

The above table has two groups: group 1 and group 2. Group 1 is a firm that adopts a work from home program and group 2 does not. Outcomes are measures of worker productivity (outputs per hour).

1.  Group 1 is treated in 1986, but group 2 is never treated. Fill in the D column and mark which periods are pre and post in the last column.

**Answer:** See table

2.  Use the switching equation to fill in column Y based on D and the potential outcomes.

**Answer:** See table

3.  Calculate the ATT for group 1 for periods 1986 to 1990.
  a. Bonus: If we wanted the ATE, what information would we need?

**Answer:** The ATT is 30 (mean of 9.99, 20, 30.02, 39.99, 50). To calculate the ATE, we would need to fill in the rest of the $y^1$ for the post-periods

4.  Calculate the difference-in-differences equation using group 2 as the comparison group to group 1. Compare your DiD equation answer to the ATT answer from question 3.
  a. If they are the same, what does that imply?
  b. If they are not the same, what does that imply?

**Answer:**

Treated group post-period mean: 41.564
Treated group pre-period mean: 6.055
Control group post-period mean: 11.588
Control group pre-period mean: 6.0683

DiD = (41.564 - 6.055) - (11.588 - 6.0683) = 29.9893

5.  Calculate the non-parallel trends bias term.

**Answer:**

Treated group post-period counterfactual mean: 11.564

Non-parallel trends bias = (11.564 - 6.055) - (11.588 - 6.0683) = -0.011


---

<table>
	<colgroup>
		<col style="width: 11%" />
		<col style="width: 14%" />
		<col style="width: 14%" />
		<col style="width: 14%" />
		<col style="width: 12%" />
		<col style="width: 15%" />
		<col style="width: 18%" />
    <col style="width: 1%" />
	</colgroup>
	<thead>
		<tr class="header">
			<th></th>
			<th></th>
			<th colspan="2"><strong>ATT STUFF</strong></th>
			<th colspan="2"><strong>DID STUFF</strong></th>
			<th></th>
      <th></th>
		</tr>
	</thead>
	<tbody>
		<tr class="odd">
			<td><strong>year</strong></td>
			<td><strong>group</strong></td>
			<td>$y^1$</td>
			<td>$y^0$</td>
			<td>$y$</td>
			<td>$D$</td>
			<td><strong>Pre/Post</strong></td>
      <td>$\delta$</td>
		</tr>
		<tr class="even">
			<td>1980</td>
			<td>1</td>
			<td></td>
			<td>3.58</td>
			<td>3.58</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="odd">
			<td>1981</td>
			<td>1</td>
			<td></td>
			<td>4.52</td>
			<td>4.52</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="even">
			<td>1982</td>
			<td>1</td>
			<td></td>
			<td>5.57</td>
			<td>5.57</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="odd">
			<td>1983</td>
			<td>1</td>
			<td></td>
			<td>6.53</td>
			<td>6.53</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="even">
			<td>1984</td>
			<td>1</td>
			<td></td>
			<td>7.57</td>
			<td>7.57</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="odd">
			<td>1985</td>
			<td>1</td>
			<td></td>
			<td>8.56</td>
			<td>8.56</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="even">
			<td>1986</td>
			<td>1</td>
			<td>19.55</td>
			<td><strong>15</strong></td>
			<td>19.55</td>
			<td>1</td>
			<td>Post</td>
      <td>4.55</td>
		</tr>
		<tr class="odd">
			<td>1987</td>
			<td>1</td>
			<td>30.59</td>
			<td><strong>25</strong></td>
			<td>30.59</td>
			<td>1</td>
			<td>Post</td>
      <td>5.59</td>
		</tr>
		<tr class="even">
			<td>1988</td>
			<td>1</td>
			<td>41.55</td>
			<td><strong>35</strong></td>
			<td>41.55</td>
			<td>1</td>
			<td>Post</td>
      <td>6.55</td>
		</tr>
		<tr class="odd">
			<td>1989</td>
			<td>1</td>
			<td>52.57</td>
			<td><strong>48</strong></td>
			<td>52.57</td>
			<td>1</td>
			<td>Post</td>
      <td>4.57</td>
		</tr>
		<tr class="even">
			<td>1990</td>
			<td>1</td>
			<td>63.56</td>
			<td><strong>60</strong></td>
			<td>63.56</td>
			<td>1</td>
			<td>Post</td>
      <td>3.56</td>
		</tr>
		<tr class="odd">
			<td>1980</td>
			<td>2</td>
			<td></td>
			<td>3.59</td>
			<td>3.59</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="even">
			<td>1981</td>
			<td>2</td>
			<td></td>
			<td>4.56</td>
			<td>4.56</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="odd">
			<td>1982</td>
			<td>2</td>
			<td></td>
			<td>5.59</td>
			<td>5.59</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="even">
			<td>1983</td>
			<td>2</td>
			<td></td>
			<td>6.54</td>
			<td>6.54</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="odd">
			<td>1984</td>
			<td>2</td>
			<td></td>
			<td>7.55</td>
			<td>7.55</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="even">
			<td>1985</td>
			<td>2</td>
			<td></td>
			<td>8.58</td>
			<td>8.58</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="odd">
			<td>1986</td>
			<td>2</td>
			<td></td>
			<td>9.58</td>
			<td>9.58</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="even">
			<td>1987</td>
			<td>2</td>
			<td></td>
			<td>10.58</td>
			<td>10.58</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="odd">
			<td>1988</td>
			<td>2</td>
			<td></td>
			<td>11.62</td>
			<td>11.62</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="even">
			<td>1989</td>
			<td>2</td>
			<td></td>
			<td>12.58</td>
			<td>12.58</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
		<tr class="odd">
			<td>1990</td>
			<td>2</td>
			<td></td>
			<td>13.58</td>
			<td>13.58</td>
			<td>0</td>
			<td>Pre</td>
      <td></td>
		</tr>
	</tbody>
</table>

_Version 2 of the same problem:_ The above table has two groups: group 1 and group 2. Group 1 is a firm that adopts a work from home program and group 2 does not. Outcomes are measures of worker productivity (outputs per hour).

1.  Group 1 is treated in 1986, but group 2 is never treated. Fill in the D column and mark which periods are pre and post in the last column.

**Answer:** See table

2.  Use the switching equation to fill in column Y based on D and the potential outcomes.

**Answer:** See table

3.  Calculate the ATT for group 1 for periods 1986 to 1990.
  a. Bonus: If we wanted the ATE, what information would we need?

**Answer:** The ATT is 4.964 (mean of 4.55, 5.59, 6.55, 4.57, 3.56). To calculate the ATE, we would need to fill in the rest of the $y^1$ for the post-periods

4.  Calculate the difference-in-differences equation using group 2 as the comparison group to group 1. Compare your DiD equation answer to the ATT answer from question 3.
  a. If they are the same, what does that imply?
  b. If they are not the same, what does that imply?

**Answer:**

Treated group post-period mean: 41.564
Treated group pre-period mean: 6.055
Control group post-period mean: 11.588
Control group pre-period mean: 6.0683

DiD = (41.564 - 6.055) - (11.588 - 6.0683) = 29.9893

They are the same. This implies that the estimator depends only on the observed outcomes and the observed treatment (which are the same between both examples).

5.  Calculate the non-parallel trends bias term.

**Answer:**

Treated group post-period counterfactual mean: 36.6

Non-parallel trends bias = (36.6 - 6.055) - (6.0683 - 11.588) = 36.0647


**Conclusion**:
In the first example, the parallel trends were zero and the DiD = ATT.

In the second example, the parallel trends term was non-zero, and the DID did not equal ATT.

Parallel trends is what allows us to get the correct answer, not the estimator because we used the same estimator both times, and in fact the Y and D columns were the same both times.

---

**Pre-trends vs parallel trends.** We use pre-trends to help us justify a diff-in-diff design. For the following questions, calculate the pre-trends for both worksheets.

1.  Write down the formula for parallel trends using potential outcomes notation



2.  Write down a DiD formula comparing the 1983 year to the 1985 baseline year for both groups

**Answer:** (8.56 - 6.53) - (8.58 - 6.54) = -0.01

3.  How are these different from one another?

There is basically no difference (statistically speaking) between the treated and control group's change in outcomes from 1983 to 1985.

4.  How informative were the pre-trends to whether parallel trends was true?

It is not informative at all. The pre-trends were the same for both examples, but the parallel trends bias term was different.

5.  What might be some reasons you can think of for why parallel trends did not hold in the second example, even though pre-trends held?

Pre-trends are an imperfect way to "test" for post-treatment parallel counterfactual trends. In a lot of instances, seeing no difference in pre-treatment trends is convincing, but it is not an actual test of post-treatment PTs.
